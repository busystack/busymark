import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:html/parser.dart' as html;
import '../markdown/audio_media.dart';
import '../markdown/audio_syntax.dart';
import '../markdown/raw_html_adapter.dart';
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

BusyAudio? parseAuthoredAudio(String? source) {
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
  return element?.localName == 'audio' ? BusyAudio.fromHtml(element!) : null;
}

BusyAudio rebaseAuthoredAudio(
  BusyAudio audio,
  String Function(String source) rebase,
) {
  final positioned = parseAuthoredAudio(audio.rawSource);
  if (positioned == null) return audio;
  final edits =
      positioned.authoredSources
          .where((source) => source.sourceSpan != null)
          .toList()
        ..sort(
          (a, b) =>
              b.sourceSpan!.startOffset.compareTo(a.sourceSpan!.startOffset),
        );
  var rewritten = audio.rawSource;
  for (final source in edits) {
    final changed = rebase(source.destination);
    if (changed == source.destination) continue;
    final span = source.sourceSpan!;
    final offset = span.startOffset;
    final quote = offset > 0 ? rewritten[offset - 1] : '';
    final encoded = escapeAuthoredHtmlAttribute(changed, switch (quote) {
      '"' => WritersideHtmlAttributeQuote.doubleQuoted,
      "'" => WritersideHtmlAttributeQuote.singleQuoted,
      _ => WritersideHtmlAttributeQuote.unquoted,
    });
    rewritten = rewritten.replaceRange(offset, span.endOffset, encoded);
  }
  return parseAuthoredAudio(rewritten) ?? audio;
}
