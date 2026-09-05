import 'writerside_source_loader.dart';

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
    final result = await WritersideSourceLoader(maximumBytes: maximumBytes)
        .load(
          reference: reference,
          documentPath: documentPath,
          workspaceRoot: workspaceRoot,
        );
    if (result.text case final text?) return text;
    throw WritersideDiagramSourceException(switch (result.failure) {
      'invalid-reference' => WritersideDiagramSourceFailure.invalidReference,
      'outside-workspace' => WritersideDiagramSourceFailure.outsideWorkspace,
      'too-large' => WritersideDiagramSourceFailure.tooLarge,
      'invalid-utf8' => WritersideDiagramSourceFailure.invalidUtf8,
      _ => WritersideDiagramSourceFailure.missing,
    });
  }
}
