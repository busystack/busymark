import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain search finds case-insensitive matches by default', () {
    final result = searchSourceDocument(
      SourceDocument(fullText: 'Alpha alpha'),
      const SourceSearchOptions(query: 'alpha'),
    );

    expect(result.totalMatchCount, 2);
    expect(result.matches.map((match) => match.fullStart), [0, 6]);
  });

  test('case-sensitive and whole-word options constrain matches', () {
    final document = SourceDocument(fullText: 'Alpha alpha alphabet');

    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: 'Alpha', caseSensitive: true),
      ).totalMatchCount,
      1,
    );
    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: 'alpha', wholeWord: true),
      ).matches.map((match) => match.fullStart),
      [0, 6],
    );
  });

  test('whole-word boundaries recognize Unicode letters and marks', () {
    final cyrillic = searchSourceDocument(
      SourceDocument(fullText: 'привет рив'),
      const SourceSearchOptions(query: 'рив', wholeWord: true),
    );
    final combining = searchSourceDocument(
      SourceDocument(fullText: 'cafe\u0301 fe'),
      const SourceSearchOptions(query: 'fe', wholeWord: true),
    );
    final cjk = searchSourceDocument(
      SourceDocument(fullText: '中文 文'),
      const SourceSearchOptions(query: '文', wholeWord: true),
    );

    expect(cyrillic.matches.map((match) => match.fullStart), [7]);
    expect(combining.matches.map((match) => match.fullStart), [6]);
    expect(cjk.matches.map((match) => match.fullStart), [3]);
  });

  test('regex search and invalid regex are safe', () {
    final document = SourceDocument(fullText: 'v1 v22 vx');

    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: r'v\d+', regex: true),
      ).matches.map((match) => match.fullEnd),
      [2, 6],
    );
    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: r'[', regex: true),
      ).invalidRegex,
      isTrue,
    );
  });

  test('navigation tracks current index and wraps', () {
    final document = SourceDocument(fullText: 'one one one');
    final controller = SourceSearchController(
      options: const SourceSearchOptions(query: 'one'),
    )..refresh(document);

    expect(controller.result.totalMatchCount, 3);
    expect(controller.next(document)?.fullStart, 0);
    expect(controller.next(document)?.fullStart, 4);
    expect(controller.previous(document)?.fullStart, 0);
    expect(controller.previous(document)?.fullStart, 8);
  });

  test('matches inside folded content are marked hidden and revealable', () {
    final document = SourceDocument(
      fullText: '# Title\nHidden text\n# Next\n',
      hiddenRanges: SourceHiddenRanges(
        ranges: const [SourceHiddenRange(start: 8, end: 20)],
        textLength: 27,
      ),
    );
    final result = searchSourceDocument(
      document,
      const SourceSearchOptions(query: 'Hidden'),
    );

    expect(result.matches.single.hidden, isTrue);
    expect(
      result.matches.single.visibleStart,
      result.matches.single.visibleEnd,
    );
  });

  test('workspace search groups authoring content by file', () {
    final results = searchWorkspaceSources(
      files: const {
        'topics/intro.md': '# Intro\nInstall BusyMark.',
        'topics/install.topic': '<topic>Install</topic>',
        'images/install.png': 'Install',
      },
      options: const SourceSearchOptions(query: 'install'),
    );

    expect(results.map((result) => result.filePath), [
      'topics/install.topic',
      'topics/intro.md',
    ]);
    expect(results.expand((result) => result.matches), hasLength(2));
  });

  test('source search worker cancels stale requests', () async {
    final worker = SourceSearchWorker();
    addTearDown(worker.dispose);
    final stale = worker.search(
      SourceDocument(fullText: List.filled(10000, 'alpha').join(' ')),
      const SourceSearchOptions(query: 'alpha'),
    );
    final current = worker.search(
      SourceDocument(fullText: 'current result'),
      const SourceSearchOptions(query: 'current'),
    );

    expect(await stale, isNull);
    expect((await current)!.totalMatchCount, 1);
  });
}
