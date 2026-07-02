import 'git_models.dart';

class GitDiffParser {
  const GitDiffParser();

  GitDiff parse(String patch, {String title = ''}) {
    final files = <GitDiffFile>[];
    _MutableDiffFile? currentFile;
    _MutableDiffHunk? currentHunk;
    var oldLine = 0;
    var newLine = 0;

    void finishHunk() {
      final hunk = currentHunk;
      final file = currentFile;
      if (hunk == null || file == null) {
        return;
      }
      file.hunks.add(hunk.toImmutable());
      currentHunk = null;
    }

    void finishFile() {
      finishHunk();
      final file = currentFile;
      if (file == null) {
        return;
      }
      files.add(file.toImmutable());
      currentFile = null;
    }

    final lines = patch.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    for (final line in lines) {
      if (line.startsWith('diff --git ')) {
        finishFile();
        final paths = _parseDiffGitPaths(line);
        currentFile = _MutableDiffFile(oldPath: paths.$1, newPath: paths.$2);
        continue;
      }
      currentFile ??= _MutableDiffFile();
      final file = currentFile;
      if (file == null) {
        continue;
      }
      if (line.startsWith('new file mode ')) {
        file.status = GitDiffFileStatus.added;
        continue;
      }
      if (line.startsWith('deleted file mode ')) {
        file.status = GitDiffFileStatus.deleted;
        continue;
      }
      if (line.startsWith('rename from ')) {
        file.oldPath = line.substring('rename from '.length);
        file.status = GitDiffFileStatus.renamed;
        continue;
      }
      if (line.startsWith('rename to ')) {
        file.newPath = line.substring('rename to '.length);
        file.status = GitDiffFileStatus.renamed;
        continue;
      }
      if (line.startsWith('copy from ')) {
        file.oldPath = line.substring('copy from '.length);
        file.status = GitDiffFileStatus.copied;
        continue;
      }
      if (line.startsWith('copy to ')) {
        file.newPath = line.substring('copy to '.length);
        file.status = GitDiffFileStatus.copied;
        continue;
      }
      if (line.startsWith('Binary files ') ||
          line.startsWith('GIT binary patch')) {
        file
          ..binary = true
          ..status = GitDiffFileStatus.binary;
        continue;
      }
      if (line.startsWith('--- ')) {
        final path = _stripDiffPathPrefix(line.substring(4).split('\t').first);
        if (path != '/dev/null') {
          file.oldPath = path;
        }
        continue;
      }
      if (line.startsWith('+++ ')) {
        final path = _stripDiffPathPrefix(line.substring(4).split('\t').first);
        if (path != '/dev/null') {
          file.newPath = path;
        }
        continue;
      }
      final hunkMatch = RegExp(
        r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@ ?(.*)$',
      ).firstMatch(line);
      if (hunkMatch != null) {
        finishHunk();
        oldLine = int.parse(hunkMatch.group(1)!);
        newLine = int.parse(hunkMatch.group(3)!);
        currentHunk = _MutableDiffHunk(
          oldStart: oldLine,
          oldCount: int.tryParse(hunkMatch.group(2) ?? '') ?? 1,
          newStart: newLine,
          newCount: int.tryParse(hunkMatch.group(4) ?? '') ?? 1,
          heading: hunkMatch.group(5) ?? '',
        );
        continue;
      }
      if (currentHunk == null) {
        continue;
      }
      final hunk = currentHunk!;
      if (line == r'\ No newline at end of file') {
        hunk.lines.add(
          GitDiffLine(kind: GitDiffLineKind.header, content: line),
        );
        continue;
      }
      if (line.startsWith('+') && !line.startsWith('+++')) {
        hunk.lines.add(
          GitDiffLine(
            kind: GitDiffLineKind.added,
            content: line.substring(1),
            newLineNumber: newLine,
          ),
        );
        file.additions += 1;
        newLine += 1;
        continue;
      }
      if (line.startsWith('-') && !line.startsWith('---')) {
        hunk.lines.add(
          GitDiffLine(
            kind: GitDiffLineKind.removed,
            content: line.substring(1),
            oldLineNumber: oldLine,
          ),
        );
        file.deletions += 1;
        oldLine += 1;
        continue;
      }
      final context = line.startsWith(' ') ? line.substring(1) : line;
      hunk.lines.add(
        GitDiffLine(
          kind: line.startsWith(' ')
              ? GitDiffLineKind.context
              : GitDiffLineKind.header,
          content: context,
          oldLineNumber: line.startsWith(' ') ? oldLine : null,
          newLineNumber: line.startsWith(' ') ? newLine : null,
        ),
      );
      if (line.startsWith(' ')) {
        oldLine += 1;
        newLine += 1;
      }
    }
    finishFile();
    return GitDiff(
      title: title,
      files: files,
      rawPatch: patch,
      hasBinaryFiles: files.any((file) => file.binary),
    );
  }

  (String?, String?) _parseDiffGitPaths(String line) {
    final rest = line.substring('diff --git '.length);
    final marker = rest.indexOf(' b/');
    if (rest.startsWith('a/') && marker > 0) {
      return (
        _stripDiffPathPrefix(rest.substring(0, marker)),
        _stripDiffPathPrefix(rest.substring(marker + 1)),
      );
    }
    final parts = rest.split(' ');
    if (parts.length >= 2) {
      return (_stripDiffPathPrefix(parts[0]), _stripDiffPathPrefix(parts[1]));
    }
    return (null, null);
  }

  String _stripDiffPathPrefix(String value) {
    if (value.startsWith('a/') || value.startsWith('b/')) {
      return value.substring(2);
    }
    return value;
  }
}

class _MutableDiffFile {
  _MutableDiffFile({this.oldPath, this.newPath});

  String? oldPath;
  String? newPath;
  GitDiffFileStatus status = GitDiffFileStatus.modified;
  final hunks = <GitDiffHunk>[];
  var binary = false;
  var additions = 0;
  var deletions = 0;

  GitDiffFile toImmutable() {
    return GitDiffFile(
      oldPath: oldPath,
      newPath: newPath,
      status: status,
      hunks: List.unmodifiable(hunks),
      binary: binary,
      additions: additions,
      deletions: deletions,
    );
  }
}

class _MutableDiffHunk {
  _MutableDiffHunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.heading,
  });

  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final String heading;
  final lines = <GitDiffLine>[];

  GitDiffHunk toImmutable() {
    return GitDiffHunk(
      oldStart: oldStart,
      oldCount: oldCount,
      newStart: newStart,
      newCount: newCount,
      heading: heading,
      lines: List.unmodifiable(lines),
    );
  }
}
