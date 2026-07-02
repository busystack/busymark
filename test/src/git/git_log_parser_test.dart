import 'package:busymark/src/git/domain/git_log_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GitLogParser();

  test('parses multiple commits', () {
    final commits = parser.parse(
      '${gitLogRecordSeparator}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      '${gitLogUnitSeparator}aaaaaaa'
      '${gitLogUnitSeparator}Ada Lovelace'
      '${gitLogUnitSeparator}ada@example.com'
      '${gitLogUnitSeparator}2026-01-02T03:04:05+00:00'
      '${gitLogUnitSeparator}Initial docs'
      '$gitLogUnitSeparator'
      '${gitLogRecordSeparator}bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
      '${gitLogUnitSeparator}bbbbbbb'
      '${gitLogUnitSeparator}Grace Hopper'
      '${gitLogUnitSeparator}grace@example.com'
      '${gitLogUnitSeparator}2026-01-03T03:04:05+00:00'
      '${gitLogUnitSeparator}Update docs'
      '${gitLogUnitSeparator}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );

    expect(commits, hasLength(2));
    expect(commits.first.subject, 'Initial docs');
    expect(commits.last.parentHashes, [
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ]);
  });

  test('parses merge commit with multiple parents', () {
    final commits = parser.parse(
      '${gitLogRecordSeparator}cccccccccccccccccccccccccccccccccccccccc'
      '${gitLogUnitSeparator}ccccccc'
      '${gitLogUnitSeparator}Maintainer'
      '${gitLogUnitSeparator}maintainer@example.com'
      '${gitLogUnitSeparator}2026-01-04T03:04:05+00:00'
      '${gitLogUnitSeparator}Merge branch docs'
      '${gitLogUnitSeparator}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    );

    expect(commits.single.parentHashes, hasLength(2));
  });

  test('preserves author punctuation and separator-like subject text', () {
    final commits = parser.parse(
      '${gitLogRecordSeparator}dddddddddddddddddddddddddddddddddddddddd'
      '${gitLogUnitSeparator}ddddddd'
      '${gitLogUnitSeparator}Docs, Inc. (Team)'
      '${gitLogUnitSeparator}docs@example.com'
      '${gitLogUnitSeparator}2026-01-05T03:04:05+00:00'
      '${gitLogUnitSeparator}Subject mentions %x1e and %x1f literally'
      '$gitLogUnitSeparator',
    );

    expect(commits.single.authorName, 'Docs, Inc. (Team)');
    expect(commits.single.subject, contains('%x1e'));
    expect(commits.single.subject, contains('%x1f'));
  });

  test('parses empty history', () {
    expect(parser.parse(''), isEmpty);
  });
}
