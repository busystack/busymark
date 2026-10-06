import 'dart:isolate';

import '../../markdown/busymark_document.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_parser.dart';
import '../../markdown/markdown_source_map.dart';
import '../../writerside/writerside_html_reference_scanner.dart';

class NotesAttachmentReference {
  const NotesAttachmentReference(
    this.reference,
    this.start,
    this.end, {
    this.image = false,
  });
  final String reference;
  final int start;
  final int end;
  final bool image;
}

Future<List<NotesAttachmentReference>> scanNotesAttachmentReferences(
  String source,
) => Isolate.run(() => notesAttachmentReferences(source));

String replaceNotesAttachmentReferences(
  String source,
  List<NotesAttachmentReference> references,
  Map<String, String> replacements,
) {
  var previousStart = source.length;
  for (final occurrence in references.reversed) {
    final replacement = replacements[occurrence.reference];
    if (replacement == null || occurrence.end > previousStart) continue;
    source = source.replaceRange(occurrence.start, occurrence.end, replacement);
    previousStart = occurrence.start;
  }
  return source;
}

/// Uses the existing positioned Markdown grammar; literal/code/prose content is
/// never rewritten when an attachment is copied into another logical note.
List<NotesAttachmentReference> notesAttachmentReferences(String source) {
  final parsed = const MarkdownParser().parse(
    filePath: '',
    source: source,
    validateLocalReferences: false,
  );
  final mask = writersideMarkdownLiteralMask(
    source: source,
    protectedRanges: parsed.codeBlocks.map((b) => b.span),
  );
  final context = const MarkdownSourceMapper().createInlineParserContext(
    documentSource: source,
    mode: MarkdownMode.commonMark,
  );
  final result = <NotesAttachmentReference>[];
  final used = <String, bool>{};
  void collect(BusyInline value) {
    if (value.destination != null &&
        (value.kind == BusyInlineKind.image ||
            value.kind == BusyInlineKind.link)) {
      used[value.destination!] =
          (used[value.destination!] ?? false) ||
          value.kind == BusyInlineKind.image;
    }
    value.children.forEach(collect);
  }

  void block(BusyBlock value) {
    for (final key in ['src', 'href', 'preview-src']) {
      final destination = value.attributes[key];
      if (destination != null) {
        used[destination] = (used[destination] ?? false) || key != 'href';
      }
    }
    value.inlines.forEach(collect);
    value.children.forEach(block);
  }

  parsed.busyDocument.blocks.forEach(block);
  for (final mapping in context.parsePositionedBlocks(source)) {
    for (final entry in mapping.ranges.entries) {
      final inline = entry.key;
      final range = entry.value;
      if (inline.destination == null ||
          (inline.kind != BusyInlineKind.image &&
              inline.kind != BusyInlineKind.link) ||
          range.isReference ||
          range.labelEnd == null) {
        continue;
      }
      var start = range.labelEnd! + 2;
      if (start >= source.length || source[range.labelEnd! + 1] != '(') {
        continue;
      }
      while (start < range.end && RegExp(r'\s').hasMatch(source[start])) {
        start++;
      }
      var end = start;
      if (start < range.end && source[start] == '<') {
        start++;
        end = source.indexOf('>', start);
        if (end < 0 || end >= range.end) continue;
      } else {
        var depth = 0;
        while (end < range.end) {
          final character = source[end];
          if (character == '\\') {
            end += 2;
            continue;
          }
          if (character == '(') {
            depth++;
          }
          if (character == ')') {
            if (depth == 0) break;
            depth--;
          }
          if (depth == 0 && RegExp(r'\s').hasMatch(character)) break;
          end++;
        }
      }
      if (end > start &&
          end <= source.length &&
          !mask.sublist(start, end).any((v) => v)) {
        result.add(
          NotesAttachmentReference(
            inline.destination!,
            start,
            end,
            image: inline.kind == BusyInlineKind.image,
          ),
        );
      }
    }
  }
  // Shared reference definitions and authored HTML retain their exact spelling.
  final definitions = RegExp(
    r'^ {0,3}\[[^\]\n]+\]:\s*(?:<([^>\n]+)>|([^\s]+))',
    multiLine: true,
  );
  final html = RegExp(
    r'''(?:src|href|preview-src)\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  for (final pattern in [definitions, html]) {
    for (final match in pattern.allMatches(source)) {
      final reference = match.group(1) ?? match.group(2);
      if (reference == null || !used.containsKey(reference)) continue;
      final start = source.indexOf(reference, match.start);
      final end = start + reference.length;
      if (start < match.start || mask.sublist(start, end).any((v) => v)) {
        continue;
      }
      result.add(
        NotesAttachmentReference(
          reference,
          start,
          end,
          image: used[reference]!,
        ),
      );
    }
  }
  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}
