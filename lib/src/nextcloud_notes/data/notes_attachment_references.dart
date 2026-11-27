import 'dart:isolate';

import '../../markdown/audio_media.dart';
import '../../references/markdown_references.dart';
import '../../writerside/writerside_html_reference_scanner.dart';

class NotesAttachmentReference {
  const NotesAttachmentReference(
    this.reference,
    this.start,
    this.end, {
    this.image = false,
    this.audio = false,
    this.quote,
    this.suffix = '',
  });
  final String reference;
  final int start;
  final int end;
  final bool image;
  final bool audio;
  final WritersideHtmlAttributeQuote? quote;
  final String suffix;
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
    final target = replacements[occurrence.reference];
    if (target == null || occurrence.end > previousStart) continue;
    final replacement = target.isEmpty ? target : target + occurrence.suffix;
    source = source.replaceRange(
      occurrence.start,
      occurrence.end,
      switch (occurrence.quote) {
        final quote? => escapeAuthoredHtmlAttribute(replacement, quote),
        null => replacement,
      },
    );
    previousStart = occurrence.start;
  }
  return source;
}

/// Uses the existing positioned Markdown grammar; literal/code/prose content is
/// never rewritten when an attachment is copied into another logical note.
List<NotesAttachmentReference> notesAttachmentReferences(String source) {
  final byStart = <int, NotesAttachmentReference>{};
  for (final item in markdownReferences(identity: '', source: source)) {
    final span = item.destinationSpan;
    if (span == null) continue;
    final image =
        item.kind == AuthoredReferenceKind.media ||
        item.kind == AuthoredReferenceKind.htmlMedia && !item.isAudio;
    final previous = byStart[span.startOffset];
    final resource = item.isAudio
        ? busyMarkAudioResourcePath(item.destination)
        : item.destination;
    byStart[span.startOffset] = NotesAttachmentReference(
      resource,
      span.startOffset,
      span.endOffset,
      image: image || previous?.image == true,
      audio: item.isAudio,
      quote: item.htmlQuote,
      suffix: item.destination.substring(resource.length),
    );
  }
  return byStart.values.toList()..sort((a, b) => a.start.compareTo(b.start));
}
