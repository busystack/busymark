import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'workspace worker reuses sequential requests and cancels an active request',
    () async {
      final worker = SourceSearchWorker();
      addTearDown(worker.dispose);
      for (final source in ['first needle', 'needle second']) {
        final result = await worker.search(
          SourceDocument(fullText: source),
          const SourceSearchOptions(query: 'needle'),
          reuseWorker: true,
        );
        expect(
          result!.matches.single.fullStart,
          source.startsWith('needle') ? 0 : 6,
        );
      }
      final slow = worker.search(
        SourceDocument(fullText: 'a ' * 400000),
        const SourceSearchOptions(query: 'a'),
        reuseWorker: true,
      );
      worker.cancel();
      expect(await slow.timeout(const Duration(seconds: 5)), isNull);
      final next = await worker.search(
        SourceDocument(fullText: 'new needle'),
        const SourceSearchOptions(query: 'needle'),
        reuseWorker: true,
      );
      expect(next!.matches.single.fullStart, 4);
    },
  );
  test(
    'regex-looking punctuation is literal and Unicode offsets remain valid',
    () {
      const source = r'😀 .* ^ $ (?=😀) \q [';
      final document = SourceDocument(fullText: source);
      for (final query in ['😀', '.*', '^', r'$', '(?=😀)', r'\q', '[']) {
        final result = searchSourceDocument(
          document,
          SourceSearchOptions(query: query),
        );
        expect(result.matches, isNotEmpty);
        for (final match in result.matches) {
          expect(source.substring(match.fullStart, match.fullEnd), query);
          expect(
            sourceSearchRangeHasSafeBoundaries(
              source,
              match.fullStart,
              match.fullEnd,
            ),
            isTrue,
          );
        }
      }
      expect(
        searchSourceDocument(
          document,
          const SourceSearchOptions(query: '.'),
        ).totalMatchCount,
        1,
      );
    },
  );

  test('workspace-style bounded matching stops after the sentinel match', () {
    final result = searchSourceDocument(
      SourceDocument(fullText: 'cat ' * 3000),
      const SourceSearchOptions(query: 'cat'),
      maximumMatches: 81,
      stopAfterMaximumMatches: true,
    );
    expect(result.matches, hasLength(81));
    expect(result.totalMatchCount, 81);
  });

  test('search worker cancels a superseded request', () async {
    final worker = SourceSearchWorker();
    addTearDown(worker.dispose);
    final slow = worker.search(
      SourceDocument(fullText: 'a ' * 400000),
      const SourceSearchOptions(query: 'a'),
    );
    final current = worker.search(
      SourceDocument(fullText: 'needle'),
      const SourceSearchOptions(query: 'needle'),
    );
    expect(await slow.timeout(const Duration(seconds: 5)), isNull);
    expect(
      (await current.timeout(const Duration(seconds: 5)))!.totalMatchCount,
      1,
    );
  });

  test('plain search finds case-insensitive matches by default', () {
    final result = searchSourceDocument(
      SourceDocument(fullText: 'Alpha alpha'),
      const SourceSearchOptions(query: 'alpha'),
    );

    expect(result.totalMatchCount, 2);
    expect(result.matches.map((match) => match.fullStart), [0, 6]);
  });

  test('literal matching includes case differences and partial words', () {
    final document = SourceDocument(fullText: 'Alpha alpha alphabet');

    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: 'Alpha'),
      ).totalMatchCount,
      3,
    );
    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: 'alpha'),
      ).matches.map((match) => match.fullStart),
      [0, 6, 12],
    );
  });

  test('Unicode substrings preserve authored source coordinates', () {
    final cyrillic = searchSourceDocument(
      SourceDocument(fullText: 'привет рив'),
      const SourceSearchOptions(query: 'рив'),
    );
    final combining = searchSourceDocument(
      SourceDocument(fullText: 'cafe\u0301 fe'),
      const SourceSearchOptions(query: 'fe'),
    );
    final cjk = searchSourceDocument(
      SourceDocument(fullText: '中文 文'),
      const SourceSearchOptions(query: '文'),
    );

    expect(cyrillic.matches.map((match) => match.fullStart), [1, 7]);
    expect(combining.matches.map((match) => match.fullStart), [2, 6]);
    expect(cjk.matches.map((match) => match.fullStart), [1, 3]);
  });

  test('regex-looking input never becomes an expression', () {
    final document = SourceDocument(fullText: r'v1 v22 vx v\d+ [');
    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: r'v\d+'),
      ).matches.map((m) => m.fullStart),
      [10],
    );
    expect(
      searchSourceDocument(
        document,
        const SourceSearchOptions(query: '['),
      ).totalMatchCount,
      1,
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

  test('source search worker bounds transferred high-match results', () async {
    final worker = SourceSearchWorker();
    addTearDown(worker.dispose);
    final source = List.filled(
      sourceInteractiveSearchMatchLimit + 500,
      'a',
    ).join();

    final firstWindow = await worker.search(
      SourceDocument(fullText: source),
      const SourceSearchOptions(query: 'a'),
    );

    expect(firstWindow, isNotNull);
    expect(firstWindow!.totalMatchCount, source.length);
    expect(firstWindow.matches, hasLength(sourceInteractiveSearchMatchLimit));
    expect(firstWindow.firstMatchIndex, 0);

    final nextWindow = await worker.search(
      SourceDocument(fullText: source),
      const SourceSearchOptions(query: 'a'),
      currentMatchIndex: sourceInteractiveSearchMatchLimit,
      firstMatchIndex: sourceInteractiveSearchMatchLimit,
    );
    expect(nextWindow, isNotNull);
    expect(nextWindow!.totalMatchCount, source.length);
    expect(nextWindow.firstMatchIndex, sourceInteractiveSearchMatchLimit);
    expect(
      nextWindow.currentMatch?.fullStart,
      sourceInteractiveSearchMatchLimit,
    );
    expect(nextWindow.matches, hasLength(500));
  });
}
