import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:path/path.dart' as p;
import 'package:html/parser.dart' as html;
import '../markdown/audio_media.dart';
import '../markdown/audio_syntax.dart';
import '../markdown/raw_html_adapter.dart';
import '../markdown/raw_html_policy.dart';
import '../writerside/writerside_html_reference_scanner.dart';

String audioReferenceMarkup(
  String reference, {
  bool localPath = false,
  String? accessibleName,
}) {
  const escape = HtmlEscape(HtmlEscapeMode.attribute);
  final destination = localPath
      ? reference.split('/').map(Uri.encodeComponent).join('/')
      : reference;
  final label = accessibleName == null
      ? ''
      : ' aria-label="${escape.convert(accessibleName)}"';
  return '<audio controls preload="none" src="${escape.convert(destination)}"$label></audio>';
}

Future<String?> resolveDocumentAudioPath(
  String reference, {
  required String documentPath,
  required String rootPath,
}) async {
  if (documentPath.isEmpty || rootPath.isEmpty) return null;
  final uri = Uri.tryParse(reference);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.path.isEmpty ||
      uri.path.startsWith('/')) {
    return null;
  }
  final root = await Directory(rootPath).resolveSymbolicLinks();
  final relative = Uri.decodeComponent(uri.path);
  if (p.isAbsolute(relative)) return null;
  final candidate = p.normalize(p.join(p.dirname(documentPath), relative));
  final path = await File(candidate).resolveSymbolicLinks();
  return p.isWithin(root, path) ? path : null;
}

dom.Element? _parseAuthoredAudioElement(String? source) {
  if (source == null ||
      authoredAudioOpening.matchAsPrefix(source) == null ||
      authoredAudioEnd(source, 0) != source.length) {
    return null;
  }
  if (const RawHtmlAdapter().parseSafeRawHtml(source) == null) return null;
  final element = html
      .parseFragment(source, generateSpans: true)
      .children
      .singleOrNull;
  return element?.localName == 'audio' ? element : null;
}

BusyAudio? parseAuthoredAudio(String? source) {
  final element = _parseAuthoredAudioElement(source);
  return element == null ? null : BusyAudio.fromHtml(element);
}

Iterable<String> authoredAudioClipboardReferences(BusyAudio audio) sync* {
  final sources = audio.authoredSources.map((source) => source.destination);
  yield* sources;
  final element = _parseAuthoredAudioElement(audio.rawSource);
  if (element == null) return;
  for (final link in element.querySelectorAll('a[href]')) {
    final href = sanitizeHtmlAttributes('a', link.attributes)?['href'];
    if (href != null && audio.ownsFallbackReference(href)) yield href;
  }
}

BusyAudio rebaseAuthoredAudio(
  BusyAudio audio,
  String Function(String reference, {required bool media}) rebase,
) {
  final element = _parseAuthoredAudioElement(audio.rawSource);
  if (element == null) return audio;
  final positioned = BusyAudio.fromHtml(element);
  final edits = <({String destination, bool media, int start, int end})>[
    for (final source in positioned.authoredSources)
      if (source.sourceSpan case final span?)
        (
          destination: source.destination,
          media: true,
          start: span.startOffset,
          end: span.endOffset,
        ),
    for (final link in element.querySelectorAll('a[href]'))
      if (sanitizeHtmlAttributes('a', link.attributes)?['href']
          case final href?)
        if (link.attributeValueSpans?['href'] case final span?)
          (
            destination: href,
            media: positioned.ownsFallbackReference(href),
            start: span.start.offset,
            end: span.end.offset,
          ),
  ]..sort((a, b) => b.start.compareTo(a.start));
  var rewritten = audio.rawSource;
  for (final source in edits) {
    final changed = rebase(source.destination, media: source.media);
    if (changed == source.destination) continue;
    final offset = source.start;
    final quote = offset > 0 ? rewritten[offset - 1] : '';
    final encoded = escapeAuthoredHtmlAttribute(changed, switch (quote) {
      '"' => WritersideHtmlAttributeQuote.doubleQuoted,
      "'" => WritersideHtmlAttributeQuote.singleQuoted,
      _ => WritersideHtmlAttributeQuote.unquoted,
    }, preserveUnquoted: true);
    rewritten = rewritten.replaceRange(offset, source.end, encoded);
  }
  return parseAuthoredAudio(rewritten) ?? audio;
}
