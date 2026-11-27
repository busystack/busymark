import 'dart:convert';

import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
// Use the same tokenizer as the HTML parser for authored element extents.
// ignore: implementation_imports
import 'package:html/src/token.dart' as html_token;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart';

import '../core/source_span.dart';
import '../writerside/writerside_html_reference_scanner.dart';
import 'audio_media.dart';
import 'audio_syntax.dart';
import 'busymark_document.dart';
import 'raw_html_policy.dart';

BusyDocument bindBusyMarkAudioSpans(
  BusyDocument document,
  Iterable<SourceSpan> protectedRanges,
) {
  final source = document.source;
  if (source == null || !authoredAudioOpening.hasMatch(source)) return document;

  final protected = writersideMarkdownLiteralMask(
    source: source,
    protectedRanges: protectedRanges,
  );
  final authored = <({int start, BusyAudio audio})>[];
  final tokenizer = HtmlTokenizer(source, generateSpans: true);
  int? opening;
  while (tokenizer.moveNext()) {
    final token = tokenizer.current;
    final span = token.span;
    if (span == null) continue;
    if (token is html_token.StartTagToken &&
        token.name == 'audio' &&
        !token.selfClosing) {
      final start = span.start.offset;
      if (protected[start] || _escaped(source, start)) continue;
      opening = start;
      continue;
    }
    if (token is! html_token.EndTagToken ||
        token.name != 'audio' ||
        opening == null ||
        protected[span.start.offset]) {
      continue;
    }
    final start = opening;
    opening = null;
    final raw = source.substring(start, span.end.offset);
    if (hasUnsafeAuthoredHtml(raw)) continue;
    final fragment = html_parser.parseFragment(raw, generateSpans: true);
    final element = fragment.nodes.singleOrNull;
    if (element is! html.Element ||
        element.localName != 'audio' ||
        !isWellFormedAudioElement(element)) {
      continue;
    }
    authored.add((start: start, audio: BusyAudio.fromHtml(element)));
  }

  String key(BusyAudio audio) => jsonEncode([
    audio.attributes,
    for (final item in audio.sources) [item.destination, item.type],
  ]);

  Iterable<BusyAudio> inlineAudio(List<BusyInline> inlines) sync* {
    for (final inline in inlines) {
      if (inline.audio case final audio?) yield audio;
      yield* inlineAudio(inline.children);
    }
  }

  Iterable<BusyAudio> blockAudio(BusyBlock block) sync* {
    if (block.audio case final audio?) yield audio;
    yield* inlineAudio(block.inlines);
    for (final child in block.children) {
      yield* blockAudio(child);
    }
  }

  int firstCandidateAt(int offset) {
    var low = 0;
    var high = authored.length;
    while (low < high) {
      final mid = low + (high - low) ~/ 2;
      if (authored[mid].start < offset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  BusyBlock bind(BusyBlock block) {
    final candidates = blockAudio(block).toList();
    final owner = block.sourceSpan;
    if (candidates.isEmpty || owner == null) return block;

    final available = <String, List<({int start, BusyAudio audio})>>{};
    for (
      var i = firstCandidateAt(owner.startOffset);
      i < authored.length && authored[i].start < owner.endOffset;
      i++
    ) {
      final item = authored[i];
      if (item.audio.sourceSpan!.endOffset + item.start <= owner.endOffset) {
        available.putIfAbsent(key(item.audio), () => []).add(item);
      }
    }
    final owners = <String, List<BusyAudio>>{};
    for (final audio in candidates) {
      owners.putIfAbsent(key(audio), () => []).add(audio);
    }

    final bindings = Map<BusyAudio, BusyAudio>.identity();
    for (final entry in owners.entries) {
      final matches = available[entry.key];
      if (matches == null || matches.length != entry.value.length) continue;
      for (final (index, audio) in entry.value.indexed) {
        final match = matches[index];
        SourceSpan? span(SourceSpan? relative) => relative == null
            ? null
            : SourceSpan.fromOffsets(
                filePath: document.filePath,
                source: source,
                startOffset: match.start + relative.startOffset,
                endOffset: match.start + relative.endOffset,
              );
        BusyAudioSource rebind(BusyAudioSource item) => BusyAudioSource(
          destination: item.destination,
          type: item.type,
          sourceSpan: span(item.sourceSpan),
        );
        bindings[audio] = BusyAudio(
          attributes: audio.attributes,
          sources: match.audio.sources.map(rebind),
          directSource: match.audio.directSource == null
              ? null
              : rebind(match.audio.directSource!),
          rawSource: audio.rawSource,
          sourceSpan: span(match.audio.sourceSpan),
        );
      }
    }
    BusyInline inline(BusyInline value) => value.copyWith(
      audio: bindings[value.audio],
      children: value.children.map(inline).toList(),
    );
    BusyBlock apply(BusyBlock value) => value.copyWith(
      audio: bindings[value.audio],
      inlines: value.inlines.map(inline).toList(),
      children: value.children.map(apply).toList(),
    );
    return bindings.isEmpty ? block : apply(block);
  }

  return document.copyWith(blocks: document.blocks.map(bind).toList());
}

bool _escaped(String source, int offset) {
  var slashCount = 0;
  for (var i = offset - 1; i >= 0 && source[i] == '\\'; i--) {
    slashCount++;
  }
  return slashCount.isOdd;
}
