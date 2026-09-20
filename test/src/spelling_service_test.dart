import 'dart:io';

import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_importer.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_word_store.dart';
import 'package:busymark/src/spellcheck/spelling_worker.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _snapshot = SpellingSnapshotIdentity(
  bufferId: 'buffer',
  contentRevision: 1,
  documentKind: DocumentKind.markdown,
  contextGeneration: 1,
);

void main() {
  group('persistent spelling words', () {
    late Directory temporary;
    late String path;

    setUp(() async {
      temporary = await Directory.systemTemp.createTemp('busymark-words-');
      path = p.join(temporary.path, 'spelling.json');
    });

    tearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });

    test('rereads and merges independent external changes', () async {
      final first = SpellingWordStore(filePath: path, projectStore: true);
      final second = SpellingWordStore(filePath: path, projectStore: true);

      await first.addWord('en-US', 'BusyMark');
      await second.addWord('en-US', 'BusyStack');
      await first.setProjectLanguage('en-US');
      final saved = await second.read();

      expect(saved.projectLanguage, 'en-US');
      expect(
        saved.wordsFor('en-US'),
        containsAll(<String>['BusyMark', 'BusyStack']),
      );
      expect(saved.revision, 3);
    });

    test('malformed storage is reported instead of overwritten', () async {
      await File(path).writeAsString('{broken');
      final store = SpellingWordStore(filePath: path);

      await expectLater(
        store.addWord('en-US', 'BusyMark'),
        throwsFormatException,
      );
      expect(await File(path).readAsString(), '{broken');
    });
  });

  test(
    'dictionary import publishes a complete pair only after validation',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-import-',
      );
      final fixture = p.join(
        Directory.current.path,
        'packages',
        'busymark_spellcheck_native',
        'test',
        'fixtures',
      );
      final imported = p.join(temporary.path, 'dictionaries');
      try {
        await const SpellingDictionaryImporter().import(
          affPath: p.join(fixture, 'test.aff'),
          dicPath: p.join(fixture, 'test.dic'),
          languageId: 'en-Test',
          displayLabel: 'Test English',
          importedRoot: imported,
          validateNativePair: (_, _) async => 'UTF-8',
        );
        final published = Directory(p.join(imported, 'en-Test'));
        expect(
          File(p.join(published.path, 'dictionary.aff')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(published.path, 'dictionary.dic')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(published.path, 'manifest.json')).existsSync(),
          isTrue,
        );

        await expectLater(
          const SpellingDictionaryImporter().import(
            affPath: p.join(fixture, 'test.aff'),
            dicPath: p.join(fixture, 'test.dic'),
            languageId: 'fr-Test',
            displayLabel: 'Broken',
            importedRoot: imported,
            validateNativePair: (_, _) async => throw StateError('rejected'),
          ),
          throwsStateError,
        );
        expect(Directory(p.join(imported, 'fr-Test')).existsSync(), isFalse);
      } finally {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      }
    },
  );

  test('Ignore Once keeps its authored anchor across editor modes', () async {
    const source = 'helo hello helo\n';
    const snapshot = SpellingSnapshotIdentity(
      bufferId: 'mode-switch',
      contentRevision: 3,
      documentKind: DocumentKind.markdown,
      contextGeneration: 2,
    );
    final document = const MarkdownParser()
        .parse(
          filePath: '/tmp/mode-switch.md',
          source: source,
          mode: MarkdownMode.commonMark,
          validateLocalReferences: false,
        )
        .busyDocument;
    final coordinator = await SpellingCoordinator.start();
    addTearDown(coordinator.dispose);
    final context = _fixtureContext(project: 'ignore-once', revision: 0);

    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: snapshot,
        engineContext: context,
        automatic: false,
        project: () async => const WysiwygSpellingProjector().project(
          document: document,
          languageId: 'en-Test',
          snapshot: snapshot,
          documentGeneration: 5,
        ),
      ),
    );
    final first = coordinator.misspellings.singleWhere(
      (occurrence) => occurrence.sourceStart == 0,
    );
    expect(coordinator.isCurrent(first), isTrue);
    coordinator.ignoreOnce(first);
    expect(coordinator.isCurrent(first), isFalse);
    expect(coordinator.annotations, hasLength(1));

    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: snapshot,
        engineContext: context,
        automatic: false,
        project: () async => const MarkdownSpellingProjector().project(
          filePath: '/tmp/mode-switch.md',
          source: source,
          mode: MarkdownMode.commonMark,
          languageId: 'en-Test',
          snapshot: snapshot,
        ),
      ),
    );

    expect(coordinator.annotations, hasLength(1));
    expect(coordinator.annotations.single.start, source.lastIndexOf('helo'));
  });

  group('long-lived spelling worker', () {
    late SpellingWorker worker;

    setUp(() async => worker = await SpellingWorker.start());
    tearDown(() => worker.close());

    test(
      'projects source and rich snapshots through reusable messages',
      () async {
        const source = '**helo** hello\n';
        final document = const MarkdownParser()
            .parse(
              filePath: '/tmp/worker-project.md',
              source: source,
              mode: MarkdownMode.commonMark,
              validateLocalReferences: false,
            )
            .busyDocument;
        final sourceProjection = await worker.project(
          const SpellingProjectionJob(
            filePath: '/tmp/worker-project.md',
            source: source,
            documentKind: DocumentKind.markdown,
            markdownMode: MarkdownMode.commonMark,
            languageId: 'en-Test',
            snapshot: _snapshot,
          ),
        );
        final richProjection = await worker.project(
          SpellingProjectionJob(
            filePath: '/tmp/worker-project.md',
            source: source,
            documentKind: DocumentKind.markdown,
            markdownMode: MarkdownMode.commonMark,
            languageId: 'en-Test',
            snapshot: _snapshot,
            richDocument: document,
            richDocumentGeneration: 4,
          ),
        );

        expect(sourceProjection.complete, isTrue);
        expect(sourceProjection.runs.single.text, 'helo hello');
        expect(richProjection.complete, isTrue);
        expect(richProjection.runs.single.text, 'helo hello');
        expect(
          richProjection.runs.single.target,
          isA<SpellingRichBlockTarget>(),
        );
      },
    );

    test('project custom words do not leak between contexts', () async {
      final accepted = await worker.check(
        context: _fixtureContext(
          project: 'one',
          revision: 1,
          words: const ['busystack'],
        ),
        runs: [_run('busystack')],
      );
      final rejected = await worker.check(
        context: _fixtureContext(project: 'two', revision: 0),
        runs: [_run('busystack')],
      );

      expect(
        accepted.occurrences.single.outcome,
        SpellingCheckOutcome.accepted,
      );
      expect(
        rejected.occurrences.single.outcome,
        SpellingCheckOutcome.rejected,
      );
    });

    test('removing a custom exception does not forbid a base word', () async {
      await worker.check(
        context: _fixtureContext(
          project: 'one',
          revision: 1,
          words: const ['hello'],
        ),
        runs: [_run('hello')],
      );
      final rebuilt = await worker.check(
        context: _fixtureContext(project: 'one', revision: 2),
        runs: [_run('hello')],
      );

      expect(rebuilt.occurrences.single.outcome, SpellingCheckOutcome.accepted);
    });

    test('bounded input failure remains unchecked and incomplete', () async {
      final result = await worker.check(
        context: _fixtureContext(project: 'one', revision: 0),
        runs: [_run('a' * (64 * 1024 + 1))],
      );

      expect(result.complete, isFalse);
      expect(result.error, contains('safety limit'));
      expect(result.occurrences.single.outcome, SpellingCheckOutcome.unchecked);
    });

    test('normal, large, and superseded checks stay bounded', () async {
      final context = _fixtureContext(project: 'performance', revision: 0);
      final normalWatch = Stopwatch()..start();
      final normal = await worker.check(
        context: context,
        runs: [_run(List.filled(200, 'hello').join(' '))],
      );
      normalWatch.stop();

      final largeRuns = [
        for (var index = 0; index < 128; index++)
          _run(List.filled(256, index.isEven ? 'hello' : 'helo').join(' ')),
      ];
      final largeWatch = Stopwatch()..start();
      final first = worker.check(context: context, runs: largeRuns);
      final superseded = worker.check(context: context, runs: largeRuns);
      final latest = worker.check(context: context, runs: largeRuns);
      final results = await Future.wait([first, superseded, latest]);
      largeWatch.stop();

      final suggestionWatch = Stopwatch()..start();
      final suggestions = await worker.suggestions(
        context: context,
        word: 'helo',
      );
      suggestionWatch.stop();
      debugPrint(
        'spelling benchmark: normal=${normalWatch.elapsedMilliseconds}ms '
        'large/latest=${largeWatch.elapsedMilliseconds}ms '
        'suggestion=${suggestionWatch.elapsedMilliseconds}ms',
      );

      expect(normal.complete, isTrue);
      expect(results.last.complete, isTrue);
      expect(results.take(2).any((result) => result.cancelled), isTrue);
      expect(suggestions, contains('hello'));
      expect(normalWatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(largeWatch.elapsed, lessThan(const Duration(seconds: 30)));
      expect(suggestionWatch.elapsed, lessThan(const Duration(seconds: 5)));
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}

SpellingEngineContext _fixtureContext({
  required String project,
  required int revision,
  List<String> words = const [],
}) {
  final fixture = p.join(
    Directory.current.path,
    'packages',
    'busymark_spellcheck_native',
    'test',
    'fixtures',
  );
  return SpellingEngineContext(
    languageId: 'en-Test',
    affPath: p.join(fixture, 'test.aff'),
    dicPath: p.join(fixture, 'test.dic'),
    baseFingerprint: 'controlled-fixture',
    personalRevision: 0,
    projectIdentity: project,
    projectRevision: revision,
    customWords: words,
  );
}

SpellingProseRun _run(String text) => SpellingProseRun(
  id: 'run-${text.length}',
  text: text,
  languageId: 'en-Test',
  atoms: const [],
  target: const SpellingSourceTarget(filePath: '/tmp/test.md'),
  snapshot: _snapshot,
);
