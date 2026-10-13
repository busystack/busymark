import 'dart:convert';
import '../core/source_span.dart';
import 'busymark_document.dart';

String nativeMarkdownInlineState(List<BusyInline> inlines) => jsonEncode([
  for (final i in inlines)
    {
      'kind': i.kind.name,
      'text': i.text,
      'destination': i.destination,
      'attributes': {
        for (final a in i.attributes.entries)
          if (!a.key.startsWith('busymark-') &&
              !a.key.startsWith('data-busymark-'))
            a.key: a.value,
      },
      'children': nativeMarkdownInlineState(i.children),
    },
]);

String nativeMarkdownAttributeState(Map<String, String> attributes) {
  final keys =
      attributes.keys
          .where(
            (k) =>
                !k.startsWith('busymark-') && !k.startsWith('data-busymark-'),
          )
          .toList()
        ..sort();
  return jsonEncode({for (final key in keys) key: attributes[key]});
}

/// Positions members inside a list already bounded by the supported parser.
/// Marker scans only locate those members; they never decide list ownership.
BusyBlock bindNativeMarkdownListSource({
  required BusyBlock list,
  required String source,
  required SourceSpan span,
  required List<({int start, int end, bool sourceOnly})> Function(String) scan,
}) {
  final marker = RegExp(r'^([ \t]*)([-+*]|\d+[.)])([ \t]+|$)');
  int columns(String whitespace) {
    var n = 0;
    for (final c in whitespace.codeUnits) {
      n += c == 9 ? 4 - n % 4 : 1;
    }
    return n;
  }

  BusyBlock bind(BusyBlock block, String text, List<int> offsets) {
    final trimmed = text.trimRight();
    final located = SourceSpan.fromOffsets(
      filePath: span.filePath,
      source: source,
      startOffset: offsets.first,
      endOffset: offsets[trimmed.length],
    );
    final attributes = {...block.attributes};
    if ({
      BusyBlockKind.unorderedListItem,
      BusyBlockKind.orderedListItem,
      BusyBlockKind.taskListItem,
    }.contains(block.kind)) {
      final opening = marker.firstMatch(text);
      if (opening != null) attributes['marker'] = opening[2]!;
    }
    var children = block.children;
    if (block.attributes['busymark-list-form'] == 'markdown') {
      var end = trimmed.length;
      if (block.attributes.containsKey(
        'busymark-writerside-source-attributes',
      )) {
        final attribute = RegExp(
          r'\r?\n[ \t]*\r?\n[ \t]*\{[^\r\n]*\}[ \t]*$',
        ).firstMatch(trimmed);
        if (attribute != null) end = attribute.start;
      }
      final starts = <int>[];
      var cursor = 0;
      int? contentIndent;
      for (final line in text.substring(0, end).split(_lineBoundaries)) {
        final m = marker.firstMatch(line);
        if (m != null &&
            (contentIndent == null || columns(m[1]!) < contentIndent)) {
          starts.add(cursor);
          final spaces = columns(m[3]!);
          contentIndent =
              columns(m[1]!) +
              m[2]!.length +
              (spaces > 4 ? 1 : spaces.clamp(1, 4));
        }
        cursor += line.length;
      }
      // A mismatch must not attach the next item or an adjacent list by guess.
      if (starts.length == children.length) {
        children = [
          for (var i = 0; i < starts.length; i++)
            bind(
              children[i],
              text.substring(
                starts[i],
                i + 1 < starts.length ? starts[i + 1] : end,
              ),
              offsets.sublist(
                starts[i],
                (i + 1 < starts.length ? starts[i + 1] : end) + 1,
              ),
            ),
        ];
      }
    } else if (block.kind == BusyBlockKind.blockquote && children.isNotEmpty) {
      final body = StringBuffer();
      final bodyOffsets = <int>[];
      var cursor = 0;
      for (final line in text.split(_lineBoundaries)) {
        final prefix = RegExp(r'^ {0,3}>[ \t]?').firstMatch(line);
        final removed = prefix?.end ?? 0;
        body.write(line.substring(removed));
        for (var j = removed; j < line.length; j++) {
          bodyOffsets.add(offsets[cursor + j]);
        }
        cursor += line.length;
      }
      bodyOffsets.add(offsets[text.length]);
      final bodyText = body.toString();
      final chunks = scan(bodyText).where((c) => !c.sourceOnly).toList();
      if (chunks.length == children.length) {
        children = [
          for (var i = 0; i < children.length; i++)
            bind(
              children[i],
              bodyText.substring(chunks[i].start, chunks[i].end),
              bodyOffsets.sublist(chunks[i].start, chunks[i].end + 1),
            ),
        ];
      }
    } else if (children.isNotEmpty && marker.hasMatch(text)) {
      final opening = marker.firstMatch(text)!;
      final indent =
          columns(opening[1]!) +
          opening[2]!.length +
          columns(opening[3]!).clamp(1, 4);
      final body = StringBuffer();
      final bodyOffsets = <int>[];
      var cursor = 0;
      for (final (index, line) in text.split(_lineBoundaries).indexed) {
        var removed = index == 0 ? opening.end : 0;
        var width = 0;
        while (index != 0 &&
            removed < line.length &&
            width < indent &&
            (line.codeUnitAt(removed) == 32 || line.codeUnitAt(removed) == 9)) {
          width += line.codeUnitAt(removed) == 9 ? 4 - width % 4 : 1;
          removed++;
        }
        // The task checkbox is part of the primary text projection.
        if (index == 0 && block.kind == BusyBlockKind.taskListItem) {
          final check = RegExp(
            r'^\[[xX ]\][ \t]+',
          ).firstMatch(line.substring(removed));
          if (check != null) removed += check.end;
        }
        body.write(line.substring(removed));
        for (var j = removed; j < line.length; j++) {
          bodyOffsets.add(offsets[cursor + j]);
        }
        cursor += line.length;
      }
      bodyOffsets.add(offsets[text.length]);
      final bodyText = body.toString();
      final chunks = scan(bodyText).where((c) => !c.sourceOnly).toList();
      final primary = block.inlines.isEmpty ? 0 : 1;
      if (chunks.length == primary + children.length) {
        children = [
          for (var i = 0; i < children.length; i++)
            bind(
              children[i],
              bodyText.substring(
                chunks[i + primary].start,
                chunks[i + primary].end,
              ),
              bodyOffsets.sublist(
                chunks[i + primary].start,
                chunks[i + primary].end + 1,
              ),
            ),
        ];
      }
    }
    return block.copyWith(
      rawSource: trimmed,
      sourceSpan: located,
      children: children,
      attributes: {
        ...attributes,
        'busymark-native-inline-state': nativeMarkdownInlineState(
          block.inlines,
        ),
        'busymark-native-attribute-state': nativeMarkdownAttributeState(
          attributes,
        ),
        'busymark-native-trailing-gap': text.substring(trimmed.length),
        'busymark-native-members': jsonEncode(
          block.children.map((b) => b.id).toList(),
        ),
        'busymark-native-source-map': jsonEncode([
          for (var i = 0; i <= trimmed.length; i++)
            if (i == 0 || offsets[i] != offsets[i - 1] + 1) [i, offsets[i]],
        ]),
      },
    );
  }

  final raw = source.substring(span.startOffset, span.endOffset);
  return bind(
    list,
    raw,
    List.generate(raw.length + 1, (i) => span.startOffset + i),
  );
}

final _lineBoundaries = RegExp(r'(?<=\n)|(?<=\r)(?!\n)');
