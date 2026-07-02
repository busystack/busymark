import 'git_models.dart';

const gitLogRecordSeparator = '\x1e';
const gitLogUnitSeparator = '\x1f';

class GitLogParser {
  const GitLogParser();

  List<GitCommitSummary> parse(String output) {
    if (output.isEmpty) {
      return const [];
    }
    final commits = <GitCommitSummary>[];
    for (final record in output.split(gitLogRecordSeparator)) {
      if (record.trim().isEmpty) {
        continue;
      }
      final fields = record.split(gitLogUnitSeparator);
      if (fields.length < 7) {
        continue;
      }
      final fullHash = fields[0].trim();
      if (fullHash.isEmpty) {
        continue;
      }
      commits.add(
        GitCommitSummary(
          fullHash: fullHash,
          shortHash: fields[1],
          authorName: fields[2],
          authorEmail: fields[3],
          authorDate:
              DateTime.tryParse(fields[4]) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          subject: fields[5],
          parentHashes: fields[6]
              .split(' ')
              .where((hash) => hash.trim().isNotEmpty)
              .toList(),
        ),
      );
    }
    return commits;
  }

  GitCommitSummary? parseFirst(String output) {
    final commits = parse(output);
    return commits.isEmpty ? null : commits.first;
  }
}
