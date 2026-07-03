import 'package:path/path.dart' as p;

import 'git_models.dart';

class GitStatusParser {
  const GitStatusParser();

  GitStatusSnapshot parsePorcelainV1Z({
    required String output,
    required GitRepositoryInfo repositoryInfo,
  }) {
    final records = output.split('\x00');
    if (records.isNotEmpty && records.last.isEmpty) {
      records.removeLast();
    }

    var info = repositoryInfo;
    final files = <GitFileStatus>[];
    for (var index = 0; index < records.length; index += 1) {
      final record = records[index];
      if (record.isEmpty) {
        continue;
      }
      if (record.startsWith('## ')) {
        info = _infoWithBranchHeader(info, record.substring(3));
        continue;
      }
      if (record.length < 4) {
        continue;
      }
      final x = record[0];
      final y = record[1];
      if (record[2] != ' ') {
        continue;
      }
      final path = record.substring(3);
      String? originalPath;
      if ((x == 'R' || x == 'C' || y == 'R' || y == 'C') &&
          index + 1 < records.length) {
        originalPath = records[++index];
      }
      final parsed = _fileStatus(
        repositoryInfo: info,
        path: path,
        originalPath: originalPath,
        x: x,
        y: y,
      );
      files.add(parsed);
    }

    final withConflicts = info.copyWith(
      hasConflicts: files.any((file) => file.conflicted),
    );
    return GitStatusSnapshot(repositoryInfo: withConflicts, files: files);
  }

  GitRepositoryInfo _infoWithBranchHeader(
    GitRepositoryInfo info,
    String header,
  ) {
    final counts = _aheadBehindFromHeader(header);
    final headerWithoutCounts = header.replaceFirst(RegExp(r'\s+\[.*\]$'), '');
    if (headerWithoutCounts == 'HEAD (no branch)') {
      return info.copyWith(
        currentBranch: null,
        aheadCount: counts.$1 ?? info.aheadCount,
        behindCount: counts.$2 ?? info.behindCount,
      );
    }
    if (headerWithoutCounts.startsWith('No commits yet on ')) {
      return info.copyWith(
        currentBranch: headerWithoutCounts.substring(
          'No commits yet on '.length,
        ),
        aheadCount: counts.$1 ?? info.aheadCount,
        behindCount: counts.$2 ?? info.behindCount,
      );
    }
    final upstreamSeparator = headerWithoutCounts.indexOf('...');
    if (upstreamSeparator >= 0) {
      return info.copyWith(
        currentBranch: headerWithoutCounts.substring(0, upstreamSeparator),
        upstreamBranch: headerWithoutCounts.substring(upstreamSeparator + 3),
        aheadCount: counts.$1 ?? info.aheadCount,
        behindCount: counts.$2 ?? info.behindCount,
      );
    }
    return info.copyWith(
      currentBranch: headerWithoutCounts,
      aheadCount: counts.$1 ?? info.aheadCount,
      behindCount: counts.$2 ?? info.behindCount,
    );
  }

  (int?, int?) _aheadBehindFromHeader(String header) {
    final bracket = RegExp(r'\[(.*)\]$').firstMatch(header);
    if (bracket == null) {
      return (null, null);
    }
    final text = bracket.group(1)!;
    final ahead = RegExp(r'ahead (\d+)').firstMatch(text);
    final behind = RegExp(r'behind (\d+)').firstMatch(text);
    return (
      ahead == null ? null : int.tryParse(ahead.group(1)!),
      behind == null ? null : int.tryParse(behind.group(1)!),
    );
  }

  GitFileStatus _fileStatus({
    required GitRepositoryInfo repositoryInfo,
    required String path,
    required String? originalPath,
    required String x,
    required String y,
  }) {
    final indexStatus = _statusFromCode(x);
    final workTreeStatus = _statusFromCode(y);
    final conflicted = _isConflict(x, y);
    final untracked = x == '?' && y == '?';
    final ignored = x == '!' && y == '!';
    final renamed = x == 'R' || y == 'R';
    final copied = x == 'C' || y == 'C';
    final deleted = x == 'D' || y == 'D';
    final staged =
        !conflicted && !untracked && !ignored && x != ' ' && x != '.';
    final unstaged =
        !conflicted && !untracked && !ignored && y != ' ' && y != '.';
    return GitFileStatus(
      repoRelativePath: path,
      absolutePath: p.normalize(p.join(repositoryInfo.rootPath, path)),
      originalRepoRelativePath: originalPath,
      indexStatus: indexStatus,
      workTreeStatus: workTreeStatus,
      category: _category(
        indexStatus: indexStatus,
        workTreeStatus: workTreeStatus,
        conflicted: conflicted,
        untracked: untracked,
        ignored: ignored,
        renamed: renamed,
        copied: copied,
        deleted: deleted,
      ),
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      deleted: deleted,
      renamed: renamed,
      copied: copied,
      conflicted: conflicted,
      ignored: ignored,
    );
  }

  GitFileChangeStatus _statusFromCode(String code) {
    return switch (code) {
      ' ' || '.' => GitFileChangeStatus.unmodified,
      'M' => GitFileChangeStatus.modified,
      'A' => GitFileChangeStatus.added,
      'D' => GitFileChangeStatus.deleted,
      'R' => GitFileChangeStatus.renamed,
      'C' => GitFileChangeStatus.copied,
      'T' => GitFileChangeStatus.typeChanged,
      'U' => GitFileChangeStatus.unmerged,
      '?' => GitFileChangeStatus.untracked,
      '!' => GitFileChangeStatus.ignored,
      _ => GitFileChangeStatus.unknown,
    };
  }

  bool _isConflict(String x, String y) {
    return const {'DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU'}.contains('$x$y');
  }

  GitFileStatusCategory _category({
    required GitFileChangeStatus indexStatus,
    required GitFileChangeStatus workTreeStatus,
    required bool conflicted,
    required bool untracked,
    required bool ignored,
    required bool renamed,
    required bool copied,
    required bool deleted,
  }) {
    if (conflicted) {
      return GitFileStatusCategory.conflicted;
    }
    if (untracked) {
      return GitFileStatusCategory.untracked;
    }
    if (ignored) {
      return GitFileStatusCategory.ignored;
    }
    if (renamed) {
      return GitFileStatusCategory.renamed;
    }
    if (copied) {
      return GitFileStatusCategory.copied;
    }
    if (deleted) {
      return GitFileStatusCategory.deleted;
    }
    if (indexStatus == GitFileChangeStatus.added ||
        workTreeStatus == GitFileChangeStatus.added) {
      return GitFileStatusCategory.added;
    }
    if (indexStatus == GitFileChangeStatus.typeChanged ||
        workTreeStatus == GitFileChangeStatus.typeChanged) {
      return GitFileStatusCategory.typeChanged;
    }
    if (indexStatus == GitFileChangeStatus.modified ||
        workTreeStatus == GitFileChangeStatus.modified) {
      return GitFileStatusCategory.modified;
    }
    return GitFileStatusCategory.unknown;
  }
}
