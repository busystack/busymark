import 'package:markdown/markdown.dart' as md;

const writersideLiteralPercentAttribute = 'data-writerside-literal-percent';

/// Preserve authored escapes until interpolation, after Markdown has decoded
/// entities and backslash escapes. An element keeps adjacent text from merging.
class WritersideLiteralPercentSyntax extends md.InlineSyntax {
  WritersideLiteralPercentSyntax()
    : super(r'&#(?:0*37|[xX]0*25);|&percnt;|\\%');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element('span', [md.Text('%')])
        ..attributes[writersideLiteralPercentAttribute] = 'true',
    );
    return true;
  }
}
