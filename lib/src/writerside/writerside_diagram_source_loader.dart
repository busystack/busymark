import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';

enum WritersideDiagramSourceFailure {
  invalidReference,
  outsideWorkspace,
  missing,
  tooLarge,
  invalidUtf8,
}

class WritersideDiagramSourceException implements Exception {
  const WritersideDiagramSourceException(this.failure);

  final WritersideDiagramSourceFailure failure;
}

/// Loads a Writerside diagram's `src` file without allowing the document to
/// escape the open project or traverse symlinks.
class WritersideDiagramSourceLoader {
  const WritersideDiagramSourceLoader({this.maximumBytes = 2 * 1024 * 1024});

  final int maximumBytes;

  Future<String> load({
    required String reference,
    required String documentPath,
    required String workspaceRoot,
  }) async {
    final source = reference.trim();
    final parsed = Uri.tryParse(source);
    if (source.isEmpty ||
        source.contains('\u0000') ||
        p.isAbsolute(source) ||
        (parsed?.hasScheme ?? false) ||
        documentPath.trim().isEmpty ||
        workspaceRoot.trim().isEmpty) {
      throw const WritersideDiagramSourceException(
        WritersideDiagramSourceFailure.invalidReference,
      );
    }

    try {
      final anchor = await captureCanonicalDirectoryAnchor(workspaceRoot);
      final candidate = p.normalize(p.join(p.dirname(documentPath), source));
      final resolved = await resolveAnchoredPath(
        anchor,
        candidate,
        allowRoot: false,
      );
      if (resolved.type != FileSystemEntityType.file) {
        throw const WritersideDiagramSourceException(
          WritersideDiagramSourceFailure.missing,
        );
      }
      final file = File(resolved.path);
      if (await file.length() > maximumBytes) {
        throw const WritersideDiagramSourceException(
          WritersideDiagramSourceFailure.tooLarge,
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maximumBytes) {
        throw const WritersideDiagramSourceException(
          WritersideDiagramSourceFailure.tooLarge,
        );
      }
      try {
        return utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        throw const WritersideDiagramSourceException(
          WritersideDiagramSourceFailure.invalidUtf8,
        );
      }
    } on WritersideDiagramSourceException {
      rethrow;
    } on AnchoredPathViolation {
      throw const WritersideDiagramSourceException(
        WritersideDiagramSourceFailure.outsideWorkspace,
      );
    } on FileSystemException {
      throw const WritersideDiagramSourceException(
        WritersideDiagramSourceFailure.missing,
      );
    }
  }
}
