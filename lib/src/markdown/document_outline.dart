import '../core/path_utils.dart';
import 'busymark_document.dart';
import 'markdown_model.dart';

/// One heading in the active document's outline.
///
/// Parsed previews provide source coordinates, while a live WYSIWYG document
/// additionally provides [editorBlockId]. Newly inserted editor blocks may not
/// have source coordinates until the serialized Markdown is parsed.
class DocumentOutlineHeading {
  const DocumentOutlineHeading({
    required this.level,
    required this.text,
    required this.id,
    this.sourceStartLine,
    this.sourceStartOffset,
    this.editorBlockId,
  });

  factory DocumentOutlineHeading.fromMarkdown(MarkdownHeading heading) {
    return DocumentOutlineHeading(
      level: heading.level,
      text: heading.text,
      id: heading.id,
      sourceStartLine: heading.span.startLine,
      sourceStartOffset: heading.span.startOffset,
    );
  }

  final int level;
  final String text;
  final String id;
  final int? sourceStartLine;
  final int? sourceStartOffset;
  final String? editorBlockId;
}

/// Projects the editable, top-level headings that serialize into the outline.
///
/// Nested headings (for example inside a blockquote) are deliberately omitted:
/// the Markdown outline scanner does not expose them either. Generated IDs are
/// recalculated from live semantic text so unsaved WYSIWYG renames and duplicate
/// suffixes stay aligned with the parser without mutating stable editor IDs.
extension BusyDocumentOutline on BusyDocument {
  List<DocumentOutlineHeading> get outline {
    final headings = <DocumentOutlineHeading>[];
    final generatedIdOccurrences = <String, int>{};

    for (final block in blocks) {
      if (block.kind != BusyBlockKind.heading) {
        continue;
      }
      final generated = block.attributes['generatedId'] != 'false';
      final id = generated
          ? nextGeneratedHeadingId(
              slugForHeading(block.plainText),
              generatedIdOccurrences,
            )
          : block.attributes['id'] ?? block.id;
      final level = (int.tryParse(block.attributes['level'] ?? '') ?? 1)
          .clamp(1, 6)
          .toInt();
      final sourceSpan = block.sourceSpan;
      headings.add(
        DocumentOutlineHeading(
          level: level,
          text: block.plainText,
          id: id,
          sourceStartLine: sourceSpan?.startLine,
          sourceStartOffset: sourceSpan?.startOffset,
          editorBlockId: block.id,
        ),
      );
    }

    return List.unmodifiable(headings);
  }
}
