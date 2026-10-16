import 'dart:math' as math;
import '../workspace/workspace_model.dart';
import '../editor/source/source_search.dart';
import '../editor/source/source_document.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import 'workspace_search_scope.dart';

class WorkspaceTextMatch {
  const WorkspaceTextMatch({
    required this.filePath,
    required this.relativePath,
    required this.fileKind,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    this.lineText,
    required this.digest,
    this.bufferId,
  });

  final String? filePath;
  final String relativePath;
  final DocumentKind fileKind;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final String? lineText;
  final String digest;
  final String? bufferId;
}

const int maxWorkspaceSearchResults = 80;
const int maxWorkspaceSearchFileBytes = 1024 * 1024;

class WorkspaceTextOutcome {
  const WorkspaceTextOutcome({
    this.matches = const [],
    this.truncated = false,
    this.skippedFiles = const [],
  });

  final List<WorkspaceTextMatch> matches;
  final bool truncated;
  final List<String> skippedFiles;
}

Future<WorkspaceTextOutcome> loadWorkspaceTextMatches(
  WorkspaceState state,
  SourceSearchOptions options, {
  required Future<String> Function(String path) loadText,
  required bool Function() isCancelled,
  required SourceSearchWorker worker,
  required int maximumResults,
  void Function(WorkspaceTextOutcome outcome)? onProgress,
}) async {
  final workspace = state.workspace;
  if (workspace == null || options.query.isEmpty || isCancelled()) {
    return const WorkspaceTextOutcome();
  }
  final results = <WorkspaceTextMatch>[];
  final skippedFiles = <String>[];
  final publicationClock = Stopwatch()..start();
  var publishedMatches = 0;
  var lastPublication = 0;
  final sortedFiles =
      workspace.files.where(isSearchableWorkspaceDocument).toList()
        ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  Future<String?> read(DocumentFile file) async {
    final buffer = state.bufferForPath(file.absolutePath);
    if (buffer != null) return buffer.text;
    if (file.absolutePath == state.activeBuffer?.filePath) {
      return state.activeText;
    }
    if (file.size > maxWorkspaceSearchFileBytes || isCancelled()) return null;
    try {
      return await loadText(file.absolutePath);
    } on Object {
      return null;
    }
  }

  // Bound read-ahead to eight eligible files. Matching remains ordered and
  // cancellable; a slow file does not serialize every subsequent disk read.
  final pending = <int, Future<String?>>{};
  var nextRead = 0;
  for (var index = 0; index < sortedFiles.length; index++) {
    if (isCancelled()) return const WorkspaceTextOutcome();
    while (nextRead < sortedFiles.length && nextRead < index + 8) {
      pending[nextRead] = read(sortedFiles[nextRead]);
      nextRead++;
    }
    final file = sortedFiles[index];
    final buffer = state.bufferForPath(file.absolutePath);
    final text = await pending.remove(index)!;
    if (isCancelled()) return const WorkspaceTextOutcome();
    if (text == null) skippedFiles.add(file.relativePath);
    if (text != null) {
      final document = SourceDocument(fullText: text);
      final search = await worker.search(
        document,
        options,
        maximumMatches: maximumResults + 1 - results.length,
        stopAfterMaximumMatches: true,
        reuseWorker: true,
      );
      if (isCancelled()) return const WorkspaceTextOutcome();
      if (search == null) {
        skippedFiles.add(file.relativePath);
      } else {
        final digest = notesSearchDigest(text);
        for (final match in search.matches) {
          final line = document.lineIndex.lineNumberAtOffset(match.fullStart);
          final sourceLine = document.lineIndex.lineAt(line);
          results.add(
            WorkspaceTextMatch(
              digest: digest,
              bufferId: buffer?.id,
              filePath: file.absolutePath,
              relativePath: file.relativePath,
              fileKind: file.kind,
              line: line,
              startOffset: match.fullStart,
              endOffset: match.fullEnd,
              query: options.query,
              lineText: boundedSearchSnippet(
                sourceLine.text,
                matchStart: match.fullStart - sourceLine.startOffset,
              ),
            ),
          );
        }
      }
    }
    // Only report truncation once an additional result was actually found.
    if (results.length > maximumResults) {
      return WorkspaceTextOutcome(
        matches: List.unmodifiable(results.take(maximumResults)),
        truncated: true,
        skippedFiles: List.unmodifiable(skippedFiles),
      );
    }
    if (onProgress != null &&
        results.length > publishedMatches &&
        (publishedMatches == 0 ||
            publicationClock.elapsedMilliseconds - lastPublication >= 50)) {
      publishedMatches = results.length;
      lastPublication = publicationClock.elapsedMilliseconds;
      onProgress(
        WorkspaceTextOutcome(
          matches: List.unmodifiable(results),
          skippedFiles: List.unmodifiable(skippedFiles),
        ),
      );
    }
  }
  return WorkspaceTextOutcome(
    matches: List.unmodifiable(results),
    skippedFiles: List.unmodifiable(skippedFiles),
  );
}

String boundedSearchSnippet(String line, {int matchStart = 0}) {
  const maximumLength = 512;
  if (line.length <= 120) return line;
  var start = math.max(0, matchStart.clamp(0, line.length) - 40);
  if (!sourceSearchRangeHasSafeBoundaries(line, start, start)) start--;
  var end = math.min(line.length, start + maximumLength - 2);
  if (!sourceSearchRangeHasSafeBoundaries(line, end, end)) end--;
  return '${start > 0 ? '…' : ''}${line.substring(start, end)}'
      '${end < line.length ? '…' : ''}';
}
