import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_downloader.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_importer.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_session_controller.dart';
import 'package:busymark/src/spellcheck/spelling_word_store.dart';
import 'package:busymark/src/spellcheck/spelling_worker.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:crypto/crypto.dart';
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
  test('downloaded dictionaries use revision-shared Snap storage', () {
    expect(
      resolveSpellingDictionaryStorageRoot(
        applicationSupportRoot: '/snap/revision/data',
        environment: const {'SNAP_USER_COMMON': '/snap/common'},
      ),
      '/snap/common/spelling/dictionaries',
    );
  });

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

  group('on-demand dictionary installation', () {
    late Directory temporary;
    late File fixtureAff;
    late File fixtureDic;
    late SpellingDictionaryResource resource;

    setUp(() async {
      temporary = await Directory.systemTemp.createTemp('busymark-download-');
      final fixture = p.join(
        Directory.current.path,
        'packages',
        'busymark_spellcheck_native',
        'test',
        'fixtures',
      );
      fixtureAff = File(p.join(fixture, 'test.aff'));
      fixtureDic = File(p.join(fixture, 'test.dic'));
      resource = SpellingDictionaryResource(
        resourceId: 'en-Test',
        id: 'en-Test',
        locales: const ['en-Test', 'en-Shared'],
        label: 'Test English',
        affSourcePath: 'fixture/test.aff',
        dicSourcePath: 'fixture/test.dic',
        affDownloadUrl: Uri.parse('https://example.invalid/test.aff'),
        dicDownloadUrl: Uri.parse('https://example.invalid/test.dic'),
        affSize: await fixtureAff.length(),
        dicSize: await fixtureDic.length(),
        affSha256: (await sha256.bind(fixtureAff.openRead()).first).toString(),
        dicSha256: (await sha256.bind(fixtureDic.openRead()).first).toString(),
        sourceRevision: 'fixture',
      );
    });

    tearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });

    Future<void> copyDownload({
      required Uri source,
      required File destination,
      required int expectedBytes,
      required SpellingDictionaryDownloadCancellation cancellation,
      required void Function(int receivedBytes) onProgress,
    }) async {
      cancellation.throwIfCancelled();
      final input = source.path.endsWith('.aff') ? fixtureAff : fixtureDic;
      final bytes = await input.readAsBytes();
      expect(bytes, hasLength(expectedBytes));
      await destination.writeAsBytes(bytes, flush: true);
      onProgress(bytes.length);
    }

    test('installs only one shared resource and reuses it by locale', () async {
      final root = p.join(temporary.path, 'downloaded');
      final installation =
          await SpellingDictionaryDownloader(
            downloadFile: copyDownload,
          ).install(
            resource: resource,
            downloadedRoot: root,
            validateNativePair: (_, _) async => 'UTF-8',
            cancellation: SpellingDictionaryDownloadCancellation(),
            onProgress: (_, _) {},
          );

      expect(installation.resourceId, 'en-Test');
      expect(
        await Directory(
          root,
        ).list().where((entity) => entity is Directory).length,
        1,
      );
      final catalogRoot = Directory(p.join(temporary.path, 'catalog'));
      await catalogRoot.create();
      await File(p.join(catalogRoot.path, 'dictionaries.json')).writeAsString(
        jsonEncode({
          'schemaVersion': 2,
          'dictionaries': [_resourceJson(resource)],
        }),
      );
      final catalog = await SpellingDictionaryCatalog.load(
        bundledRoot: catalogRoot.path,
        downloadedRoot: root,
      );
      expect(catalog.availableEntries, hasLength(1));
      expect(
        catalog.installedById('en-Test'),
        same(catalog.installedById('en-Shared')),
      );
    });

    test('cancellation and checksum failure leave no installation', () async {
      final cancelledRoot = p.join(temporary.path, 'cancelled');
      final cancellation = SpellingDictionaryDownloadCancellation();
      await expectLater(
        SpellingDictionaryDownloader(
          downloadFile:
              ({
                required source,
                required destination,
                required expectedBytes,
                required cancellation,
                required onProgress,
              }) async {
                cancellation.cancel();
                cancellation.throwIfCancelled();
              },
        ).install(
          resource: resource,
          downloadedRoot: cancelledRoot,
          validateNativePair: (_, _) async => 'UTF-8',
          cancellation: cancellation,
          onProgress: (_, _) {},
        ),
        throwsA(isA<SpellingDictionaryDownloadCancelled>()),
      );
      expect(await _publishedDirectories(cancelledRoot), isEmpty);

      final badRoot = p.join(temporary.path, 'bad-checksum');
      final badResource = SpellingDictionaryResource(
        resourceId: resource.resourceId,
        id: resource.id,
        locales: resource.locales,
        label: resource.label,
        affSourcePath: resource.affSourcePath,
        dicSourcePath: resource.dicSourcePath,
        affDownloadUrl: resource.affDownloadUrl,
        dicDownloadUrl: resource.dicDownloadUrl,
        affSize: resource.affSize,
        dicSize: resource.dicSize,
        affSha256: '0' * 64,
        dicSha256: resource.dicSha256,
        sourceRevision: resource.sourceRevision,
      );
      await expectLater(
        SpellingDictionaryDownloader(downloadFile: copyDownload).install(
          resource: badResource,
          downloadedRoot: badRoot,
          validateNativePair: (_, _) async => 'UTF-8',
          cancellation: SpellingDictionaryDownloadCancellation(),
          onProgress: (_, _) {},
        ),
        throwsFormatException,
      );
      expect(await _publishedDirectories(badRoot), isEmpty);
    });

    test('a failed replacement cannot damage a working installation', () async {
      final root = p.join(temporary.path, 'working');
      final installed =
          await SpellingDictionaryDownloader(
            downloadFile: copyDownload,
          ).install(
            resource: resource,
            downloadedRoot: root,
            validateNativePair: (_, _) async => 'UTF-8',
            cancellation: SpellingDictionaryDownloadCancellation(),
            onProgress: (_, _) {},
          );
      final originalAff = await File(installed.affPath).readAsBytes();
      final originalDic = await File(installed.dicPath).readAsBytes();
      final badResource = SpellingDictionaryResource(
        resourceId: resource.resourceId,
        id: resource.id,
        locales: resource.locales,
        label: resource.label,
        affSourcePath: resource.affSourcePath,
        dicSourcePath: resource.dicSourcePath,
        affDownloadUrl: resource.affDownloadUrl,
        dicDownloadUrl: resource.dicDownloadUrl,
        affSize: resource.affSize,
        dicSize: resource.dicSize,
        affSha256: '0' * 64,
        dicSha256: resource.dicSha256,
        sourceRevision: resource.sourceRevision,
      );

      await expectLater(
        SpellingDictionaryDownloader(downloadFile: copyDownload).install(
          resource: badResource,
          downloadedRoot: root,
          validateNativePair: (_, _) async => 'UTF-8',
          cancellation: SpellingDictionaryDownloadCancellation(),
          onProgress: (_, _) {},
        ),
        throwsFormatException,
      );

      expect(await _publishedDirectories(root), hasLength(1));
      expect(await File(installed.affPath).readAsBytes(), originalAff);
      expect(await File(installed.dicPath).readAsBytes(), originalDic);
    });

    test('a failed controller download exposes a working retry', () async {
      final catalogRoot = Directory(p.join(temporary.path, 'catalog'));
      await catalogRoot.create();
      await File(p.join(catalogRoot.path, 'dictionaries.json')).writeAsString(
        jsonEncode({
          'schemaVersion': 2,
          'dictionaries': [_resourceJson(resource)],
        }),
      );
      var failNextDownload = true;
      final controller = SpellingSessionController(
        bundledRoot: catalogRoot.path,
        applicationSupportRoot: p.join(temporary.path, 'support'),
        dictionaryStorageRoot: p.join(temporary.path, 'managed'),
        dictionaryDownloader: SpellingDictionaryDownloader(
          downloadFile:
              ({
                required source,
                required destination,
                required expectedBytes,
                required cancellation,
                required onProgress,
              }) async {
                if (failNextDownload) {
                  failNextDownload = false;
                  throw const SocketException('test download failure');
                }
                await copyDownload(
                  source: source,
                  destination: destination,
                  expectedBytes: expectedBytes,
                  cancellation: cancellation,
                  onProgress: onProgress,
                );
              },
        ),
      );
      addTearDown(controller.dispose);
      await controller.prepareSettings(null);

      await expectLater(
        controller.installDictionary(resource.id),
        throwsA(isA<SocketException>()),
      );
      expect(
        controller.dictionaryInstallStatus?.phase,
        SpellingDictionaryInstallPhase.failed,
      );

      await controller.retryDictionaryInstallation();

      expect(controller.dictionaryInstallStatus, isNull);
      expect(controller.catalog?.installedById(resource.id), isNotNull);
      expect(
        await _publishedDirectories(
          p.join(temporary.path, 'managed', 'downloaded'),
        ),
        hasLength(1),
      );
    });
  });

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

  test(
    'document ignores survive tab changes but not an actual close',
    () async {
      final coordinator = await SpellingCoordinator.start();
      addTearDown(coordinator.dispose);
      final context = _fixtureContext(project: 'ignore-lifecycle', revision: 0);
      const firstSnapshot = SpellingSnapshotIdentity(
        bufferId: 'first',
        contentRevision: 1,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );
      const secondSnapshot = SpellingSnapshotIdentity(
        bufferId: 'second',
        contentRevision: 1,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );

      Future<SpellingOccurrence> check(
        SpellingSnapshotIdentity snapshot,
      ) async {
        await coordinator.checkNow(
          SpellingCheckRequest(
            snapshot: snapshot,
            engineContext: context,
            automatic: false,
            project: () async => SpellingProjectionResult(
              runs: [_runFor('helo', snapshot: snapshot)],
              complete: true,
            ),
          ),
        );
        return coordinator.misspellings.single;
      }

      final first = await check(firstSnapshot);
      coordinator.ignoreAllInDocument(first);
      expect(coordinator.isCurrent(first), isFalse);

      await check(secondSnapshot);
      final returned = await check(firstSnapshot);
      expect(coordinator.isCurrent(returned), isFalse);

      coordinator.closeBuffer(firstSnapshot.bufferId);
      final reopened = await check(firstSnapshot);
      expect(coordinator.isCurrent(reopened), isTrue);
    },
  );

  test('a delayed suggestion cannot revive after language changes', () async {
    final delayed = Completer<List<String>>();
    final coordinator = await SpellingCoordinator.start(
      suggestionLookup: (_, _) => delayed.future,
    );
    addTearDown(coordinator.dispose);
    const oldSnapshot = SpellingSnapshotIdentity(
      bufferId: 'language-change',
      contentRevision: 4,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    const newSnapshot = SpellingSnapshotIdentity(
      bufferId: 'language-change',
      contentRevision: 4,
      documentKind: DocumentKind.markdown,
      contextGeneration: 2,
    );
    final oldContext = _fixtureContext(
      project: 'language-change',
      revision: 0,
      languageId: 'en-Old',
    );
    final newContext = _fixtureContext(
      project: 'language-change',
      revision: 0,
      languageId: 'en-New',
    );

    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: oldSnapshot,
        engineContext: oldContext,
        automatic: false,
        project: () async => SpellingProjectionResult(
          runs: [_runFor('helo', snapshot: oldSnapshot, languageId: 'en-Old')],
          complete: true,
        ),
      ),
    );
    final oldOccurrence = coordinator.misspellings.single;
    final oldSuggestions = coordinator.suggestions(
      oldOccurrence,
      context: oldContext,
    );

    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: newSnapshot,
        engineContext: newContext,
        automatic: false,
        project: () async => SpellingProjectionResult(
          runs: [_runFor('helo', snapshot: newSnapshot, languageId: 'en-New')],
          complete: true,
        ),
      ),
    );
    final newOccurrence = coordinator.misspellings.single;
    delayed.complete(const ['hello']);

    await expectLater(oldSuggestions, throwsStateError);
    expect(coordinator.isCurrent(oldOccurrence), isFalse);
    expect(coordinator.isCurrent(newOccurrence), isTrue);
    expect(oldOccurrence.id, isNot(newOccurrence.id));
  });

  test('equivalent rebuild does not cancel session initialization', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-session-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final bundle = await _createFixtureBundle(temporary);
    final controller = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
    );
    addTearDown(controller.dispose);
    final buffer = DocumentBuffer.untitled(
      id: 'equivalent-input',
      name: 'equivalent.md',
      text: 'helo',
    );
    final settings = AppSettings.defaults().copyWith(
      defaultSpellingLanguage: 'en-Test',
    );
    final first = SpellingSessionInput(
      buffer: buffer,
      workspace: null,
      settings: settings,
      documentKind: DocumentKind.markdown,
      markdownMode: MarkdownMode.commonMark,
    );
    final equivalent = SpellingSessionInput(
      buffer: buffer,
      workspace: null,
      settings: settings,
      documentKind: DocumentKind.markdown,
      markdownMode: MarkdownMode.commonMark,
    );

    controller.update(first);
    controller.update(equivalent);
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.ready,
    );

    expect(controller.misspellings.single.word, 'helo');

    final changedController = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'changed-support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
    );
    addTearDown(changedController.dispose);
    changedController.update(first);
    changedController.update(
      SpellingSessionInput(
        buffer: buffer.copyWith(text: 'hello', revision: 1),
        workspace: null,
        settings: settings,
        documentKind: DocumentKind.markdown,
        markdownMode: MarkdownMode.commonMark,
      ),
    );
    await _waitFor(
      () => changedController.state.status == SpellingPresentationStatus.ready,
    );
    expect(changedController.misspellings, isEmpty);
  });

  test(
    'an available but absent dictionary is not downloaded implicitly',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-not-installed-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final bundle = await _createFixtureBundle(temporary);
      final dictionaryStorage = Directory(
        p.join(temporary.path, 'dictionary-storage'),
      );
      await dictionaryStorage.delete(recursive: true);
      final controller = SpellingSessionController(
        bundledRoot: bundle,
        applicationSupportRoot: p.join(temporary.path, 'support'),
        dictionaryStorageRoot: dictionaryStorage.path,
        verifyDictionaryChecksums: false,
      );
      addTearDown(controller.dispose);
      final buffer = DocumentBuffer.untitled(
        id: 'not-installed',
        name: 'not-installed.md',
        text: 'helo',
      );
      controller.update(
        SpellingSessionInput(
          buffer: buffer,
          workspace: null,
          settings: AppSettings.defaults().copyWith(
            defaultSpellingLanguage: 'en-Test',
          ),
          documentKind: DocumentKind.markdown,
          markdownMode: MarkdownMode.commonMark,
        ),
      );
      await _waitFor(
        () =>
            controller.state.status ==
            SpellingPresentationStatus.dictionaryNotInstalled,
      );

      expect(controller.catalog?.availableById('en-Test'), isNotNull);
      expect(controller.catalog?.installedById('en-Test'), isNull);
      expect(await _publishedDirectories(dictionaryStorage.path), isEmpty);
    },
  );

  test(
    'removing a downloaded pair keeps words and reports not installed',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-remove-dictionary-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final bundle = await _createFixtureBundle(temporary);
      final support = p.join(temporary.path, 'support');
      final personal = SpellingWordStore(
        filePath: p.join(support, 'spelling', 'personal.json'),
      );
      await personal.addWord('en-Test', 'BusyMarkTerm');
      final controller = SpellingSessionController(
        bundledRoot: bundle,
        applicationSupportRoot: support,
        dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      );
      addTearDown(controller.dispose);
      final buffer = DocumentBuffer.untitled(
        id: 'remove-installed',
        name: 'remove-installed.md',
        text: 'helo',
      );
      controller.update(
        SpellingSessionInput(
          buffer: buffer,
          workspace: null,
          settings: AppSettings.defaults().copyWith(
            defaultSpellingLanguage: 'en-Test',
          ),
          documentKind: DocumentKind.markdown,
          markdownMode: MarkdownMode.commonMark,
        ),
      );
      await _waitFor(
        () => controller.state.status == SpellingPresentationStatus.ready,
      );
      await controller.removeDownloadedDictionary('en-Test');
      await _waitFor(
        () =>
            controller.state.status ==
            SpellingPresentationStatus.dictionaryNotInstalled,
      );

      expect(controller.catalog?.installedById('en-Test'), isNull);
      expect(
        (await personal.read()).wordsFor('en-Test'),
        contains('BusyMarkTerm'),
      );
    },
  );

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

      expect(accepted.occurrences, isEmpty);
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

      expect(rebuilt.occurrences, isEmpty);
    });

    test('prose around 64 KiB is checked across bounded chunks', () async {
      final fixtures = [
        List.filled(10000, 'hello').join(' '),
        List.filled(8000, 'hello 🙂').join(' '),
      ];
      expect(utf8.encode(fixtures.first).length, lessThan(64 * 1024));
      expect(utf8.encode(fixtures.last).length, greaterThan(64 * 1024));

      for (final middle in fixtures) {
        final text = 'helo $middle helo';
        final result = await worker.check(
          context: _fixtureContext(project: 'one', revision: 0),
          runs: [_run(text)],
        );

        expect(result.complete, isTrue);
        expect(result.error, isNull);
        expect(result.occurrences.map((item) => item.word), ['helo', 'helo']);
        expect(result.occurrences.first.logicalStart, 0);
        expect(result.occurrences.last.logicalEnd, text.length);
      }
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
  String languageId = 'en-Test',
}) {
  final fixture = p.join(
    Directory.current.path,
    'packages',
    'busymark_spellcheck_native',
    'test',
    'fixtures',
  );
  return SpellingEngineContext(
    languageId: languageId,
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

SpellingProseRun _runFor(
  String text, {
  required SpellingSnapshotIdentity snapshot,
  String languageId = 'en-Test',
}) => SpellingProseRun(
  id: 'run-${text.length}',
  text: text,
  languageId: languageId,
  atoms: const [],
  target: const SpellingSourceTarget(filePath: '/tmp/test.md'),
  snapshot: snapshot,
);

Future<String> _createFixtureBundle(Directory temporary) async {
  final fixture = p.join(
    Directory.current.path,
    'packages',
    'busymark_spellcheck_native',
    'test',
    'fixtures',
  );
  final bundle = Directory(p.join(temporary.path, 'bundle'));
  await bundle.create(recursive: true);
  final sourceAff = File(p.join(fixture, 'test.aff'));
  final sourceDic = File(p.join(fixture, 'test.dic'));
  final affChecksum = await sha256.bind(sourceAff.openRead()).first;
  final dicChecksum = await sha256.bind(sourceDic.openRead()).first;
  await File(p.join(bundle.path, 'dictionaries.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 2,
      'dictionaries': [
        {
          'resourceId': 'en-Test',
          'id': 'en-Test',
          'locales': ['en-Test'],
          'label': 'Test English',
          'affSourcePath': 'test/test.aff',
          'dicSourcePath': 'test/test.dic',
          'affDownloadUrl': 'https://example.invalid/test.aff',
          'dicDownloadUrl': 'https://example.invalid/test.dic',
          'affSize': await sourceAff.length(),
          'dicSize': await sourceDic.length(),
          'sourceRevision': 'fixture',
          'affSha256': affChecksum.toString(),
          'dicSha256': dicChecksum.toString(),
        },
      ],
    }),
  );
  final installed = Directory(
    p.join(temporary.path, 'dictionary-storage', 'downloaded', 'en-Test'),
  );
  await installed.create(recursive: true);
  await sourceAff.copy(p.join(installed.path, 'dictionary.aff'));
  await sourceDic.copy(p.join(installed.path, 'dictionary.dic'));
  await File(p.join(installed.path, 'manifest.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'kind': 'downloaded',
      'resourceId': 'en-Test',
      'id': 'en-Test',
      'locales': ['en-Test'],
      'label': 'Test English',
      'sourceRevision': 'fixture',
      'affPath': 'dictionary.aff',
      'dicPath': 'dictionary.dic',
      'affSha256': affChecksum.toString(),
      'dicSha256': dicChecksum.toString(),
    }),
  );
  return bundle.path;
}

Map<String, Object?> _resourceJson(SpellingDictionaryResource resource) => {
  'resourceId': resource.resourceId,
  'id': resource.id,
  'locales': resource.locales,
  'label': resource.label,
  'affSourcePath': resource.affSourcePath,
  'dicSourcePath': resource.dicSourcePath,
  'affDownloadUrl': resource.affDownloadUrl.toString(),
  'dicDownloadUrl': resource.dicDownloadUrl.toString(),
  'affSize': resource.affSize,
  'dicSize': resource.dicSize,
  'sourceRevision': resource.sourceRevision,
  'affSha256': resource.affSha256,
  'dicSha256': resource.dicSha256,
};

Future<List<FileSystemEntity>> _publishedDirectories(String rootPath) async {
  final root = Directory(rootPath);
  if (!await root.exists()) return const [];
  return root
      .list()
      .where(
        (entity) =>
            entity is Directory && !p.basename(entity.path).startsWith('.'),
      )
      .toList();
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final watch = Stopwatch()..start();
  while (!predicate()) {
    if (watch.elapsed > timeout) {
      throw TimeoutException('Timed out waiting for spelling state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
