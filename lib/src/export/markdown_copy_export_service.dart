import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../assets/document_media_context.dart';
import '../core/atomic_file_writer.dart';
import '../nextcloud_notes/data/notes_attachment_references.dart';

/// Exports one remote Markdown buffer and provider-owned media as a local copy.
/// The live note identity and stored Markdown are never changed.
class MarkdownCopyExportService {
  const MarkdownCopyExportService({this.maximumBytes = 256 * 1024 * 1024});
  final int maximumBytes;

  Future<void> export({
    required String source,
    required String destinationPath,
    required DocumentMediaContext media,
    bool overwrite = false,
  }) async {
    final occurrences = await scanNotesAttachmentReferences(source);
    final references = occurrences.map((r) => r.reference).toSet();
    final destination = p.normalize(p.absolute(destinationPath));
    final parent = Directory(p.dirname(destination));
    final staging = await parent.createTemp('.busymark-note-copy-');
    final folderName =
        '${p.basenameWithoutExtension(destination)}.attachments-${const Uuid().v4()}';
    final published = Directory(p.join(parent.path, folderName));
    var ownsPublished = false;
    var totalBytes = 0;
    final replacements = <String, String>{};
    try {
      final assets = Directory(p.join(staging.path, 'assets'));
      await assets.create();
      for (final reference in references) {
        final uri = Uri.tryParse(reference);
        if (uri?.scheme == 'https' ||
            uri?.scheme == 'http' ||
            reference.startsWith('#')) {
          continue;
        }
        final path = await media.resolve(reference);
        if (path == null) {
          if (reference.startsWith('busymark-attachment:') ||
              RegExp(r'^\.attachments\.\d+/').hasMatch(reference)) {
            throw const FileSystemException(
              'A note attachment is unavailable. Connect or restore its durable bytes before exporting.',
            );
          }
          continue;
        }
        final file = File(path);
        final size = await file.length();
        if (size < 0 || totalBytes + size > maximumBytes) {
          throw const FileSystemException(
            'The note attachments exceed the export size limit.',
          );
        }
        final bytes = await file.readAsBytes();
        totalBytes += bytes.length;
        final extension = p.extension(path).toLowerCase();
        final name = '${sha256.convert(bytes)}$extension';
        await File(p.join(assets.path, name)).writeAsBytes(bytes, flush: true);
        final replacement = Uri(pathSegments: [folderName, name]).toString();
        replacements[reference] = replacement;
      }
      final exported = replaceNotesAttachmentReferences(
        source,
        occurrences,
        replacements,
      );
      if (replacements.isNotEmpty) {
        await assets.rename(published.path);
        ownsPublished = true;
      }
      await const AtomicFileWriter().writeBytes(
        destination,
        utf8.encode(exported),
        overwrite: overwrite,
      );
      ownsPublished = false;
    } finally {
      if (ownsPublished && await published.exists()) {
        await published.delete(recursive: true);
      }
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }
}
