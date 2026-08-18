import 'dart:convert';
import 'dart:typed_data';

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
        file.oldPath = _decodeGitPath(line.substring('rename from '.length));
        file.status = GitDiffFileStatus.renamed;
        continue;
      }
      if (line.startsWith('rename to ')) {
        file.newPath = _decodeGitPath(line.substring('rename to '.length));
        file.status = GitDiffFileStatus.renamed;
        continue;
      }
      if (line.startsWith('copy from ')) {
        file.oldPath = _decodeGitPath(line.substring('copy from '.length));
        file.status = GitDiffFileStatus.copied;
        continue;
      }
      if (line.startsWith('copy to ')) {
        file.newPath = _decodeGitPath(line.substring('copy to '.length));
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
        final path = _parsePatchHeaderPath(line.substring(4));
        if (path != '/dev/null') {
          file.oldPath = path;
        }
        continue;
      }
      if (line.startsWith('+++ ')) {
        final path = _parsePatchHeaderPath(line.substring(4));
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
    if (rest.startsWith('"')) {
      final first = _readQuotedPath(rest, 0);
      if (first == null) {
        return (null, null);
      }
      var secondStart = first.$2;
      while (secondStart < rest.length &&
          rest.codeUnitAt(secondStart) == 0x20) {
        secondStart += 1;
      }
      if (secondStart >= rest.length) {
        return (null, null);
      }
      final second = rest.startsWith('"', secondStart)
          ? _readQuotedPath(rest, secondStart)?.$1
          : rest.substring(secondStart);
      if (second == null) {
        return (null, null);
      }
      return (
        _stripDiffPathPrefix(_decodeGitPath(first.$1)),
        _stripDiffPathPrefix(_decodeGitPath(second)),
      );
    }
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

  String _parsePatchHeaderPath(String value) {
    final token = value.split('\t').first;
    return _stripDiffPathPrefix(_decodeGitPath(token));
  }

  (String, int)? _readQuotedPath(String value, int start) {
    if (start >= value.length || value.codeUnitAt(start) != 0x22) {
      return null;
    }
    var index = start + 1;
    while (index < value.length) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit == 0x5c) {
        index += 2;
        continue;
      }
      if (codeUnit == 0x22) {
        return (value.substring(start, index + 1), index + 1);
      }
      index += 1;
    }
    return null;
  }

  String _decodeGitPath(String value) {
    if (value.length < 2 ||
        value.codeUnitAt(0) != 0x22 ||
        value.codeUnitAt(value.length - 1) != 0x22) {
      return value;
    }
    final output = BytesBuilder(copy: false);
    var index = 1;
    final end = value.length - 1;
    while (index < end) {
      if (value.codeUnitAt(index) != 0x5c) {
        index = _appendUtf8Rune(output, value, index);
        continue;
      }
      index += 1;
      if (index >= end) {
        output.addByte(0x5c);
        break;
      }
      final escaped = value.codeUnitAt(index);
      if (_isOctalDigit(escaped)) {
        var byte = 0;
        var digits = 0;
        while (index < end &&
            digits < 3 &&
            _isOctalDigit(value.codeUnitAt(index))) {
          byte = (byte * 8) + value.codeUnitAt(index) - 0x30;
          index += 1;
          digits += 1;
        }
        output.addByte(byte);
        continue;
      }
      final simpleEscape = const <int, int>{
        0x61: 0x07,
        0x62: 0x08,
        0x74: 0x09,
        0x6e: 0x0a,
        0x76: 0x0b,
        0x66: 0x0c,
        0x72: 0x0d,
        0x22: 0x22,
        0x5c: 0x5c,
      }[escaped];
      if (simpleEscape != null) {
        output.addByte(simpleEscape);
        index += 1;
        continue;
      }
      output.addByte(0x5c);
      index = _appendUtf8Rune(output, value, index);
    }
    return utf8.decode(output.takeBytes(), allowMalformed: true);
  }

  int _appendUtf8Rune(BytesBuilder output, String value, int index) {
    final firstCodeUnit = value.codeUnitAt(index);
    final hasSurrogatePair =
        firstCodeUnit >= 0xd800 &&
        firstCodeUnit <= 0xdbff &&
        index + 1 < value.length &&
        value.codeUnitAt(index + 1) >= 0xdc00 &&
        value.codeUnitAt(index + 1) <= 0xdfff;
    final nextIndex = index + (hasSurrogatePair ? 2 : 1);
    output.add(utf8.encode(value.substring(index, nextIndex)));
    return nextIndex;
  }

  bool _isOctalDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x37;

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
