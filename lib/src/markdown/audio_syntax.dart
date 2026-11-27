import 'package:markdown/markdown.dart' as md;
// The HTML tokenizer provides authored tag boundaries and ignores closing
// tag lookalikes in attributes and comments.
// ignore: implementation_imports
import 'package:html/src/token.dart' as token;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart';

import 'markdown_source_annotation.dart';
import 'raw_html_policy.dart';

const busyMarkAudioInlineTag = 'busymark-audio-inline';

final authoredAudioOpening = RegExp(r'<audio(?=[\s/>])', caseSensitive: false);
final _authoredInlineOpening = RegExp(
  r'<([a-z][a-z0-9-]*)(?=[\s/>])',
  caseSensitive: false,
);
final _lastAudioOpening = Expando<int>();
final _audioWrapperEnds = Expando<Map<int, int>>();

/// Keeps the HTML contents together before Markdown link, emphasis and
/// autolink processing can reinterpret fallback text within a media element.
class BusyAudioInlineSyntax extends md.InlineHtmlSyntax {
  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    final start = startMatchPos ?? parser.pos;
    final source = parser.source;
    if (source.codeUnitAt(start) != 0x3c) return false;
    final lastAudio = _lastAudioOpening[parser] ??=
        authoredAudioOpening.allMatches(source).lastOrNull?.start ?? -1;
    if (start > lastAudio) return false;
    final tag = _authoredInlineOpening
        .matchAsPrefix(source, start)
        ?.group(1)
        ?.toLowerCase();
    if (tag == null ||
        !safeInlineHtmlTags.contains(tag) ||
        voidHtmlTags.contains(tag)) {
      return false;
    }
    final end = tag == 'audio'
        ? authoredAudioEnd(source, start)
        : (_audioWrapperEnds[parser] ??= _authoredAudioWrapperEnds(
            source,
          ))[start];
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

/// Find safe, explicitly closed inline wrappers with audio children in one
/// pass. With ordinary HTML syntax their parts would be split around audio.
Map<int, int> _authoredAudioWrapperEnds(String source) {
  final tokenizer = HtmlTokenizer(source, generateSpans: true);
  final open = <({String name, int start, int audioCount, int literalCount})>[];
  final wrapped = <int, int>{};
  var audioCount = 0;
  var literalCount = 0;
  while (tokenizer.moveNext()) {
    final current = tokenizer.current;
    final span = current.span;
    if (current is token.StartTagToken) {
      final name = current.name;
      if (span == null ||
          name == null ||
          !safeInlineHtmlTags.contains(name) ||
          _isEscaped(source, span.start.offset)) {
        open.clear();
        continue;
      }
      if (!current.selfClosing && !voidHtmlTags.contains(name)) {
        open.add((
          name: name,
          start: span.start.offset,
          audioCount: audioCount,
          literalCount: literalCount,
        ));
      }
    } else if (current is token.EndTagToken) {
      if (open.isEmpty) continue;
      if (span == null ||
          open.last.name != current.name ||
          _isEscaped(source, span.start.offset)) {
        open.clear();
        continue;
      }
      final element = open.removeLast();
      if (element.name == 'audio') {
        audioCount++;
      } else if (audioCount > element.audioCount &&
          literalCount == element.literalCount) {
        wrapped[element.start] = span.end.offset;
      }
    } else if (current is token.CharactersToken && current.data.contains('`')) {
      // Let the Markdown parser classify code spans before any tag in them
      // can be treated as audio. A neighboring genuine audio stays eligible.
      literalCount++;
    }
  }
  return wrapped;
}

bool _isEscaped(String source, int offset) {
  var backslashes = 0;
  for (var i = offset - 1; i >= 0 && source[i] == '\\'; i--) {
    backslashes++;
  }
  return backslashes.isOdd;
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
