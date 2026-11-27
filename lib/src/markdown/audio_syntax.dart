import 'package:markdown/markdown.dart' as md;
// The HTML tokenizer provides authored tag boundaries and ignores closing
// tag lookalikes in attributes and comments.
// ignore: implementation_imports
import 'package:html/src/token.dart' as token;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart';

import 'markdown_source_annotation.dart';

const busyMarkAudioInlineTag = 'busymark-audio-inline';

final authoredAudioOpening = RegExp(r'<audio(?=[\s/>])', caseSensitive: false);

/// Keeps the HTML contents together before Markdown link, emphasis and
/// autolink processing can reinterpret fallback text within a media element.
class BusyAudioInlineSyntax extends md.InlineHtmlSyntax {
  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    final start = startMatchPos ?? parser.pos;
    if (parser.source.codeUnitAt(start) != 0x3c ||
        authoredAudioOpening.matchAsPrefix(parser.source, start) == null) {
      return false;
    }
    final end = authoredAudioEnd(parser.source, start);
    // An incomplete candidate must leave matching to the ordinary HTML or
    // text syntax. InlineSyntax.onMatch(false) would leave the cursor parked.
    if (end == null) return false;
    parser.writeText();
    addAudioNode(parser, start, end);
    parser.consume(end - parser.pos);
    return true;
  }

  void addAudioNode(md.InlineParser parser, int start, int end) {
    final element = md.Element.text(
      busyMarkAudioInlineTag,
      parser.source.substring(start, end),
    );
    element.attributes[busyMarkSourceMappingStartAttribute] = '$start';
    element.attributes[busyMarkSourceMappingEndAttribute] = '$end';
    parser.addNode(element);
  }
}

int? authoredAudioEnd(String source, int start) {
  final tokenizer = HtmlTokenizer(source.substring(start), generateSpans: true);
  if (!tokenizer.moveNext()) return null;
  final opening = tokenizer.current;
  if (opening is! token.StartTagToken ||
      opening.name != 'audio' ||
      opening.selfClosing) {
    return null;
  }
  while (tokenizer.moveNext()) {
    final current = tokenizer.current;
    if (current is token.EndTagToken && current.name == 'audio') {
      final end = current.span?.end.offset;
      return end == null ? null : start + end;
    }
    if (current is token.StartTagToken && current.name == 'audio') return null;
  }
  return null;
}
