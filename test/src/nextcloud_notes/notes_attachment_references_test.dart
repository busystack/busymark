import 'package:busymark/src/nextcloud_notes/data/notes_attachment_references.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'attachment recovery finds positioned inline and reference destinations',
    () {
      const source =
          '![inline](.attachments.1/a%20b.png "title")\n'
          '[download](<.attachments.1/document.pdf>)\n'
          '![shared][asset]\n\n[asset]: .attachments.1/shared.png\n';
      final references = notesAttachmentReferences(source);
      expect(references.map((r) => r.reference), [
        '.attachments.1/a%20b.png',
        '.attachments.1/document.pdf',
        '.attachments.1/shared.png',
      ]);
      for (final reference in references) {
        expect(
          source.substring(reference.start, reference.end),
          reference.reference,
        );
      }
    },
  );

  test('authored HTML attachments retain exact attribute positions', () {
    const source =
        '<img src=".attachments.1/photo.png" alt="image">\n\n'
        '<a href=".attachments.1/document.pdf">download</a>\n';
    final references = notesAttachmentReferences(source);
    expect(references.map((r) => r.reference), [
      '.attachments.1/photo.png',
      '.attachments.1/document.pdf',
    ]);
    for (final reference in references) {
      expect(
        source.substring(reference.start, reference.end),
        reference.reference,
      );
    }
  });

  test(
    'literal code, comments and prose do not become attachment operations',
    () {
      const source =
          '.attachments.1/plain.png\n'
          '`![inline](.attachments.1/code.png)`\n\n'
          '```markdown\n![fenced](.attachments.1/fenced.png)\n```\n'
          '<!-- <img src=".attachments.1/comment.png"> -->\n';
      expect(notesAttachmentReferences(source), isEmpty);
    },
  );
}
