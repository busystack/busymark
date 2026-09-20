import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/atomic_file_writer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_coordinator.dart';
import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_downloader.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_importer.dart';
import 'package:busymark/src/spellcheck/spelling_dictionary_installer.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_session_controller.dart';
import 'package:busymark/src/spellcheck/spelling_word_store.dart';
import 'package:busymark/src/spellcheck/spelling_worker.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/presentation/workspace_screen.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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

      await Future.wait([
        first.addWord('en-US', 'BusyMark'),
        second.addWord('en-US', 'BusyStack'),
      ]);
      await first.setProjectLanguage('en-US');
      final saved = await second.read();

      expect(saved.projectLanguage, 'en-US');
      expect(
        saved.wordsFor('en-US'),
        containsAll(<String>['BusyMark', 'BusyStack']),
      );
      expect(saved.revision, 3);
    });

    test(
      'preserves case while merging canonical Unicode equivalents',
      () async {
        final store = SpellingWordStore(filePath: path);

        await store.addWord('en-US', 'BusyBrand');
        await store.addWord('en-US', 'busybrand');
        await store.addWord('en-US', 'Cafe\u0301');
        await store.addWord('en-US', 'Café');
        var saved = await store.read();

        expect(saved.wordsFor('en-US'), ['BusyBrand', 'Café', 'busybrand']);
        await store.removeWord('en-US', 'BusyBrand');
        saved = await store.read();
        expect(saved.wordsFor('en-US'), ['Café', 'busybrand']);
      },
    );

    test(
      'rebuilds untrusted stored keys from validated display values',
      () async {
        await File(path).writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'revision': 4,
            'words': {
              'en-US': [
                {'key': 'forged-key', 'display': 'BusyBrand'},
              ],
            },
          }),
        );

        final saved = await SpellingWordStore(filePath: path).read();
        expect(saved.wordsByLanguage['en-US']!.single.key, 'BusyBrand');
        await expectLater(
          SpellingWordStore(filePath: path).addWord('en-US', 'bad\u0001word'),
          throwsArgumentError,
        );
      },
    );

    test(
      'case-distinct words survive restart into the native worker',
      () async {
        final store = SpellingWordStore(filePath: path);
        var saved = await store.addWord('en-Test', 'BusyBrand');
        final worker = await SpellingWorker.start();
        addTearDown(worker.close);

        var result = await worker.check(
          context: _fixtureContext(
            project: 'persistent-case',
            revision: saved.revision,
            words: saved.wordsFor('en-Test').toList(),
          ),
          runs: [_run('BusyBrand busybrand')],
        );
        expect(result.occurrences.map((item) => item.word), ['busybrand']);

        saved = await SpellingWordStore(
          filePath: path,
        ).addWord('en-Test', 'busybrand');
        result = await worker.check(
          context: _fixtureContext(
            project: 'persistent-case',
            revision: saved.revision,
            words: saved.wordsFor('en-Test').toList(),
          ),
          runs: [_run('BusyBrand busybrand')],
        );
        expect(result.occurrences, isEmpty);
      },
    );

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
    'staging validation accepts numeric header revisions and count drift',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-dictionary-structure-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final aff = File(p.join(temporary.path, 'test.aff'));
      final dic = File(p.join(temporary.path, 'test.dic'));
      final affBytes = utf8.encode('SET UTF-8\n');
      final dicBytes = utf8.encode('2\t1\nhello\n');
      await aff.writeAsBytes(affBytes);
      await dic.writeAsBytes(dicBytes);

      await expectLater(
        validateSpellingDictionaryPair(
          affSource: aff,
          dicSource: dic,
          expectedAffSize: affBytes.length,
          expectedDicSize: dicBytes.length,
          expectedAffSha256: sha256.convert(affBytes).toString(),
          expectedDicSha256: sha256.convert(dicBytes).toString(),
        ),
        completes,
      );

      final emptyBytes = utf8.encode('1\n');
      await dic.writeAsBytes(emptyBytes);
      await expectLater(
        validateSpellingDictionaryPair(
          affSource: aff,
          dicSource: dic,
          expectedAffSize: affBytes.length,
          expectedDicSize: emptyBytes.length,
          expectedAffSha256: sha256.convert(affBytes).toString(),
          expectedDicSha256: sha256.convert(emptyBytes).toString(),
        ),
        throwsFormatException,
      );
    },
  );

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
          validateNativePair: (_, _, _) async => 'UTF-8',
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
            validateNativePair: (_, _, _) async => throw StateError('rejected'),
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
        knownValidProbe: 'hello',
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
            validateNativePair: (_, _, _) async => 'UTF-8',
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
          validateNativePair: (_, _, _) async => 'UTF-8',
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
        knownValidProbe: resource.knownValidProbe,
      );
      await expectLater(
        SpellingDictionaryDownloader(downloadFile: copyDownload).install(
          resource: badResource,
          downloadedRoot: badRoot,
          validateNativePair: (_, _, _) async => 'UTF-8',
          cancellation: SpellingDictionaryDownloadCancellation(),
          onProgress: (_, _) {},
        ),
        throwsFormatException,
      );
      expect(await _publishedDirectories(badRoot), isEmpty);
    });

    test('cancellation observes the atomic publication commit point', () async {
      final beforeRoot = p.join(temporary.path, 'cancel-before-commit');
      var guardCalls = 0;
      await expectLater(
        const SpellingDictionaryPairInstaller().install(
          affSource: fixtureAff,
          dicSource: fixtureDic,
          spec: SpellingDictionaryInstallSpec.downloaded(resource),
          destinationRoot: beforeRoot,
          validateNativePair: (_, _, _) async => 'UTF-8',
          cancellationGuard: () {
            guardCalls++;
            if (guardCalls == 4) {
              throw const SpellingDictionaryDownloadCancelled();
            }
          },
        ),
        throwsA(isA<SpellingDictionaryDownloadCancelled>()),
      );
      expect(await _publishedDirectories(beforeRoot), isEmpty);

      final afterRoot = p.join(temporary.path, 'cancel-after-commit');
      final cancellation = SpellingDictionaryDownloadCancellation();
      final installation =
          await SpellingDictionaryDownloader(
            installer: SpellingDictionaryPairInstaller(
              onCommitted: (_) => cancellation.cancel(),
            ),
            downloadFile: copyDownload,
          ).install(
            resource: resource,
            downloadedRoot: afterRoot,
            validateNativePair: (_, _, _) async => 'UTF-8',
            cancellation: cancellation,
            onProgress: (_, _) {},
          );

      expect(cancellation.isCancelled, isTrue);
      expect(Directory(installation.directoryPath).existsSync(), isTrue);
      expect(await _publishedDirectories(afterRoot), hasLength(1));
    });

    test('stalled response times out, cancels, and permits retry', () async {
      final body = StreamController<List<int>>();
      final cancelled = Completer<void>();
      body.onCancel = () {
        if (!cancelled.isCompleted) cancelled.complete();
      };
      body.add(const [1]);
      final destination = File(p.join(temporary.path, 'stalled.dic'));

      await expectLater(
        receiveSpellingDictionaryBody(
          bytes: body.stream,
          destination: destination,
          expectedBytes: 2,
          cancellation: SpellingDictionaryDownloadCancellation(),
          onProgress: (_) {},
          inactivityTimeout: const Duration(milliseconds: 30),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await cancelled.future;

      await receiveSpellingDictionaryBody(
        bytes: Stream.fromIterable(const [
          [1],
          [2],
        ]),
        destination: destination,
        expectedBytes: 2,
        cancellation: SpellingDictionaryDownloadCancellation(),
        onProgress: (_) {},
        inactivityTimeout: const Duration(milliseconds: 30),
      );
      expect(await destination.readAsBytes(), [1, 2]);
    });

    test('a failed replacement cannot damage a working installation', () async {
      final root = p.join(temporary.path, 'working');
      final installed =
          await SpellingDictionaryDownloader(
            downloadFile: copyDownload,
          ).install(
            resource: resource,
            downloadedRoot: root,
            validateNativePair: (_, _, _) async => 'UTF-8',
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
        knownValidProbe: resource.knownValidProbe,
      );

      await expectLater(
        SpellingDictionaryDownloader(downloadFile: copyDownload).install(
          resource: badResource,
          downloadedRoot: root,
          validateNativePair: (_, _, _) async => 'UTF-8',
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

  test(
    'aliased imports remain selectable across collision, restart, and removal',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-alias-import-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final fixture = await _createAliasedFixtureBundle(temporary);
      final support = p.join(temporary.path, 'support');
      final storage = p.join(temporary.path, 'dictionary-storage');
      var controller = SpellingSessionController(
        bundledRoot: fixture.bundle,
        applicationSupportRoot: support,
        dictionaryStorageRoot: storage,
        verifyDictionaryChecksums: false,
      );
      await controller.prepareSettings(null);
      expect(controller.catalog!.installedById('nl-AW')!.imported, isFalse);

      await controller.importDictionary(
        affPath: fixture.aff,
        dicPath: fixture.dic,
        languageId: 'nl-NL',
        displayLabel: 'Imported Dutch',
      );
      final imported = controller.catalog!.installedById('nl-NL')!;
      expect(imported.id, 'nl-NL');
      expect(imported.imported, isTrue);
      expect(
        controller.catalog!.entries.where((entry) => entry.id == 'nl-NL'),
        hasLength(1),
      );
      final input = SpellingSessionInput(
        buffer: DocumentBuffer.untitled(
          id: 'alias-import',
          name: 'alias.md',
          text: 'helo',
        ),
        workspace: null,
        settings: AppSettings.defaults().copyWith(
          defaultSpellingLanguage: 'nl-NL',
        ),
        documentKind: DocumentKind.markdown,
        markdownMode: MarkdownMode.commonMark,
      );
      controller.update(input);
      await _waitFor(
        () => controller.state.status == SpellingPresentationStatus.ready,
      );
      expect(controller.effectiveLanguage, 'nl-NL');
      expect(controller.misspellings.single.word, 'helo');
      controller.dispose();

      controller = SpellingSessionController(
        bundledRoot: fixture.bundle,
        applicationSupportRoot: support,
        dictionaryStorageRoot: storage,
        verifyDictionaryChecksums: false,
      );
      addTearDown(controller.dispose);
      controller.update(input.refreshed());
      await _waitFor(
        () => controller.state.status == SpellingPresentationStatus.ready,
      );
      expect(controller.catalog!.installedById('nl-NL')!.imported, isTrue);

      await controller.removeImportedDictionary('nl-NL');
      expect(
        controller.catalog!.installations.where(
          (installation) => installation.id == 'nl-NL',
        ),
        isEmpty,
      );
      expect(controller.catalog!.installedById('nl-AW')!.imported, isFalse);
      expect(controller.catalog!.installedById('nl-NL')!.id, 'nl-AW');
    },
  );

  test(
    'invalid downloaded installation repairs through settings API',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-dictionary-repair-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final bundle = await _createFixtureBundle(temporary);
      final fixture = p.join(
        Directory.current.path,
        'packages',
        'busymark_spellcheck_native',
        'test',
        'fixtures',
      );
      final fixtureAff = File(p.join(fixture, 'test.aff'));
      final fixtureDic = File(p.join(fixture, 'test.dic'));
      final storage = p.join(temporary.path, 'dictionary-storage');
      await File(
        p.join(storage, 'downloaded', 'en-Test', 'dictionary.dic'),
      ).delete();
      var notifications = 0;
      final controller = SpellingSessionController(
        bundledRoot: bundle,
        applicationSupportRoot: p.join(temporary.path, 'support'),
        dictionaryStorageRoot: storage,
        verifyDictionaryChecksums: false,
        dictionaryDownloader: SpellingDictionaryDownloader(
          downloadFile:
              ({
                required source,
                required destination,
                required expectedBytes,
                required cancellation,
                required onProgress,
              }) async {
                cancellation.throwIfCancelled();
                final sourceFile = source.path.endsWith('.aff')
                    ? fixtureAff
                    : fixtureDic;
                final bytes = await sourceFile.readAsBytes();
                expect(bytes, hasLength(expectedBytes));
                await destination.writeAsBytes(bytes, flush: true);
                onProgress(bytes.length);
              },
        ),
      )..addListener(() => notifications++);
      addTearDown(controller.dispose);
      await controller.prepareSettings(null);
      expect(controller.catalog!.installedById('en-Test'), isNull);
      expect(controller.catalog!.invalidById('en-Test'), isNotNull);

      final beforeInstall = notifications;
      await controller.installDictionary('en-Test');

      expect(controller.dictionaryInstallStatus, isNull);
      expect(controller.catalog!.invalidById('en-Test'), isNull);
      expect(controller.catalog!.installedById('en-Test'), isNotNull);
      expect(notifications, greaterThan(beforeInstall));
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

  test(
    'source hit testing excludes formatting and link destination gaps',
    () async {
      const source = '**mispel**led [mispelled](destination)\n';
      const snapshot = SpellingSnapshotIdentity(
        bufferId: 'source-hit-segments',
        contentRevision: 1,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );
      final coordinator = await SpellingCoordinator.start();
      addTearDown(coordinator.dispose);
      await coordinator.checkNow(
        SpellingCheckRequest(
          snapshot: snapshot,
          engineContext: _fixtureContext(project: 'source-hit', revision: 0),
          automatic: false,
          project: () async => const MarkdownSpellingProjector().project(
            filePath: '/tmp/source-hit.md',
            source: source,
            mode: MarkdownMode.commonMark,
            languageId: 'en-Test',
            snapshot: snapshot,
          ),
        ),
      );

      expect(coordinator.misspellings, hasLength(2));
      expect(coordinator.occurrenceAtSource(0), isNull);
      expect(coordinator.occurrenceAtSource(3)?.word, 'mispelled');
      expect(coordinator.occurrenceAtSource(8), isNull);
      expect(
        coordinator.occurrenceAtSource(source.indexOf('destination') + 2),
        isNull,
      );
      expect(
        coordinator.occurrenceAtSource(source.indexOf('[mispelled]') + 2)?.word,
        'mispelled',
      );
    },
  );

  test(
    'Ignore Once follows one transaction across edit, undo, redo, and tabs',
    () async {
      const bufferId = 'anchor-transactions';
      final coordinator = await SpellingCoordinator.start();
      addTearDown(coordinator.dispose);
      final context = _fixtureContext(project: 'anchors', revision: 0);

      Future<void> check(String source, int revision, {String id = bufferId}) {
        final snapshot = SpellingSnapshotIdentity(
          bufferId: id,
          contentRevision: revision,
          documentKind: DocumentKind.markdown,
          contextGeneration: 1,
        );
        return coordinator.checkNow(
          SpellingCheckRequest(
            snapshot: snapshot,
            engineContext: context,
            automatic: false,
            project: () async => MarkdownSpellingProjector().project(
              filePath: '/tmp/$id.md',
              source: source,
              mode: MarkdownMode.commonMark,
              languageId: 'en-Test',
              snapshot: snapshot,
            ),
          ),
        );
      }

      await check('helo hello helo', 1);
      coordinator.ignoreOnce(coordinator.misspellings.last);
      coordinator.translateSourceEdit(
        bufferId: bufferId,
        start: 0,
        oldEnd: 0,
        newEnd: 4,
      );
      await check('sun helo hello helo', 2);
      expect(coordinator.annotations.map((item) => item.start), [4]);

      coordinator.translateSourceEdit(
        bufferId: bufferId,
        start: 0,
        oldEnd: 4,
        newEnd: 0,
      );
      await check('helo hello helo', 3);
      expect(coordinator.annotations.map((item) => item.start), [0]);

      coordinator.translateSourceEdit(
        bufferId: bufferId,
        start: 0,
        oldEnd: 0,
        newEnd: 4,
      );
      await check('sun helo hello helo', 4);
      expect(coordinator.annotations.map((item) => item.start), [4]);
      coordinator.translateSourceEdit(
        bufferId: bufferId,
        start: 0,
        oldEnd: 4,
        newEnd: 0,
      );
      await check('helo hello helo', 5);

      coordinator.translateSourceEdit(
        bufferId: bufferId,
        start: 0,
        oldEnd: 4,
        newEnd: 5,
      );
      await check('hello hello helo', 6);
      expect(coordinator.annotations, isEmpty);

      await check('helo', 1, id: 'other-tab');
      await check('hello hello helo', 6);
      expect(coordinator.annotations, isEmpty);

      coordinator.invalidateBufferAnchors(bufferId);
      await check('hello hello helo', 7);
      expect(coordinator.annotations.single.start, 'hello hello '.length);
      coordinator.ignoreOnce(coordinator.misspellings.single);
      coordinator.closeBuffer(bufferId);
      await check('hello hello helo', 8);
      expect(coordinator.annotations, hasLength(1));
    },
  );

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

  test(
    'a manual request waits for its own result while a check runs',
    () async {
      final coordinator = await SpellingCoordinator.start();
      addTearDown(coordinator.dispose);
      final firstProjection = Completer<SpellingProjectionResult>();
      var firstProjectionStarted = false;
      const firstSnapshot = SpellingSnapshotIdentity(
        bufferId: 'manual-wait',
        contentRevision: 1,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );
      const secondSnapshot = SpellingSnapshotIdentity(
        bufferId: 'manual-wait',
        contentRevision: 2,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );
      final context = _fixtureContext(project: 'manual-wait', revision: 0);

      final first = coordinator.checkNow(
        SpellingCheckRequest(
          snapshot: firstSnapshot,
          engineContext: context,
          automatic: false,
          project: () {
            firstProjectionStarted = true;
            return firstProjection.future;
          },
        ),
      );
      await _waitFor(() => firstProjectionStarted);
      var secondCompleted = false;
      final second = coordinator
          .checkNow(
            SpellingCheckRequest(
              snapshot: secondSnapshot,
              engineContext: context,
              automatic: false,
              project: () async => SpellingProjectionResult(
                runs: [_runFor('helo', snapshot: secondSnapshot)],
                complete: true,
              ),
            ),
          )
          .whenComplete(() => secondCompleted = true);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(secondCompleted, isFalse);
      firstProjection.complete(
        SpellingProjectionResult(
          runs: [_runFor('hello', snapshot: firstSnapshot)],
          complete: true,
        ),
      );
      await Future.wait([first, second]);

      expect(secondCompleted, isTrue);
      expect(coordinator.state.status, SpellingPresentationStatus.ready);
      expect(coordinator.misspellings.single.word, 'helo');
      expect(coordinator.misspellings.single.run.snapshot, secondSnapshot);
    },
  );

  test('checks in bounded batches and reuses unchanged run results', () async {
    final coordinator = await SpellingCoordinator.start();
    addTearDown(coordinator.dispose);
    final context = _fixtureContext(project: 'progressive', revision: 0);
    final publications = <({SpellingPresentationStatus status, int count})>[];
    void listen() => publications.add((
      status: coordinator.state.status,
      count: coordinator.state.occurrences.length,
    ));
    coordinator.addListener(listen);
    addTearDown(() => coordinator.removeListener(listen));

    List<SpellingProseRun> runs(SpellingSnapshotIdentity snapshot) => [
      for (var index = 0; index < 25; index++)
        SpellingProseRun(
          id: 'progressive-$index',
          text: 'helo',
          languageId: 'en-Test',
          atoms: const [],
          target: const SpellingSourceTarget(filePath: '/tmp/progressive.md'),
          snapshot: snapshot,
        ),
    ];

    const firstSnapshot = SpellingSnapshotIdentity(
      bufferId: 'progressive',
      contentRevision: 1,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: firstSnapshot,
        engineContext: context,
        automatic: false,
        project: () async =>
            SpellingProjectionResult(runs: runs(firstSnapshot), complete: true),
      ),
    );
    expect(coordinator.misspellings, hasLength(25));
    expect(
      publications.any(
        (state) =>
            state.status == SpellingPresentationStatus.checking &&
            state.count > 0 &&
            state.count < 25,
      ),
      isTrue,
    );

    publications.clear();
    const secondSnapshot = SpellingSnapshotIdentity(
      bufferId: 'progressive',
      contentRevision: 2,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    await coordinator.checkNow(
      SpellingCheckRequest(
        snapshot: secondSnapshot,
        engineContext: context,
        automatic: false,
        project: () async => SpellingProjectionResult(
          runs: runs(secondSnapshot),
          complete: true,
        ),
      ),
    );

    expect(coordinator.misspellings, hasLength(25));
    expect(
      publications.any(
        (state) =>
            state.status == SpellingPresentationStatus.checking &&
            state.count == 25,
      ),
      isTrue,
    );
  });

  test('project initialization publishes only the latest owner', () async {
    for (final completeLatestFirst in [true, false]) {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-project-race-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final bundle = await _createFixtureBundle(temporary);
      final firstRoot = p.join(temporary.path, 'first');
      final secondRoot = p.join(temporary.path, 'second');
      await Directory(firstRoot).create();
      await Directory(secondRoot).create();
      final firstRead = Completer<SpellingWordStoreSnapshot>();
      final secondRead = Completer<SpellingWordStoreSnapshot>();
      var firstStarted = false;
      var secondStarted = false;
      final controller = SpellingSessionController(
        bundledRoot: bundle,
        applicationSupportRoot: p.join(temporary.path, 'support'),
        dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
        verifyDictionaryChecksums: false,
        wordStoreReader: (store) {
          if (!store.projectStore) return store.read();
          if (p.isWithin(firstRoot, store.filePath)) {
            firstStarted = true;
            return firstRead.future;
          }
          secondStarted = true;
          return secondRead.future;
        },
      );
      addTearDown(controller.dispose);
      final settings = AppSettings.defaults().copyWith(
        defaultSpellingLanguage: 'en-Test',
      );

      controller.update(
        _sessionInput(
          id: 'first-buffer',
          root: firstRoot,
          text: 'FirstProjectWord',
          settings: settings,
        ),
      );
      await _waitFor(() => firstStarted);
      controller.update(
        _sessionInput(
          id: 'second-buffer',
          root: secondRoot,
          text: 'SecondProjectWord',
          settings: settings,
        ),
      );
      await _waitFor(() => secondStarted);
      final firstSnapshot = _wordSnapshot('FirstProjectWord');
      final secondSnapshot = _wordSnapshot('SecondProjectWord');
      if (completeLatestFirst) {
        secondRead.complete(secondSnapshot);
        firstRead.complete(firstSnapshot);
      } else {
        firstRead.complete(firstSnapshot);
        secondRead.complete(secondSnapshot);
      }
      await _waitFor(
        () => controller.state.status == SpellingPresentationStatus.ready,
      );

      expect(controller.projectWords.wordsFor('en-Test'), [
        'SecondProjectWord',
      ]);
      expect(controller.misspellings, isEmpty);
      controller.dispose();
    }
  });

  test('concurrent first requests start exactly one worker', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-worker-start-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final bundle = await _createFixtureBundle(temporary);
    final root = p.join(temporary.path, 'project');
    await Directory(root).create();
    final startupGate = Completer<void>();
    var starts = 0;
    final controller = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
      coordinatorStarter: () async {
        starts++;
        await startupGate.future;
        return SpellingCoordinator.start();
      },
    );
    addTearDown(controller.dispose);
    final settings = AppSettings.defaults().copyWith(
      defaultSpellingLanguage: 'en-Test',
    );

    controller.update(
      _sessionInput(
        id: 'startup',
        root: root,
        text: 'helo',
        settings: settings,
      ),
    );
    await _waitFor(() => starts == 1);
    controller.update(
      _sessionInput(
        id: 'startup',
        root: root,
        text: 'helo again',
        revision: 1,
        settings: settings,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(starts, 1);
    startupGate.complete();
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.ready,
    );
    expect(starts, 1);
  });

  test('a project-word mutation cannot publish into a later project', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-project-mutation-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final bundle = await _createFixtureBundle(temporary);
    final firstRoot = p.join(temporary.path, 'first');
    final secondRoot = p.join(temporary.path, 'second');
    await Directory(firstRoot).create();
    await Directory(secondRoot).create();
    final delayedWriter = _DelayedAtomicFileWriter();
    addTearDown(delayedWriter.releaseIfNeeded);
    final controller = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
      wordStoreFactory: ({required filePath, required projectStore}) =>
          SpellingWordStore(
            filePath: filePath,
            projectStore: projectStore,
            writer: projectStore && p.isWithin(firstRoot, filePath)
                ? delayedWriter
                : const AtomicFileWriter(),
          ),
    );
    addTearDown(controller.dispose);
    final settings = AppSettings.defaults().copyWith(
      defaultSpellingLanguage: 'en-Test',
    );
    controller.update(
      _sessionInput(
        id: 'first-mutation',
        root: firstRoot,
        text: 'ProjectTypoo',
        settings: settings,
      ),
    );
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.ready,
    );
    final occurrence = controller.misspellings.single;
    final mutation = controller.addProjectWord(occurrence);
    await delayedWriter.started.future;

    controller.update(
      _sessionInput(
        id: 'second-mutation',
        root: secondRoot,
        text: 'helo',
        settings: settings,
      ),
    );
    await _waitFor(
      () =>
          controller.state.status == SpellingPresentationStatus.ready &&
          controller.misspellings.singleOrNull?.word == 'helo',
    );
    delayedWriter.releaseIfNeeded();
    await mutation;

    expect(controller.projectWords.wordsFor('en-Test'), isEmpty);
    expect(
      (await SpellingWordStore(
        filePath: p.join(firstRoot, '.busymark', 'spelling.json'),
        projectStore: true,
      ).read()).wordsFor('en-Test'),
      ['ProjectTypoo'],
    );
  });

  test('new input hides old results before preparation can fail', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-preparation-failure-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final bundle = await _createFixtureBundle(temporary);
    final goodRoot = p.join(temporary.path, 'good');
    final badRoot = p.join(temporary.path, 'bad');
    await Directory(goodRoot).create();
    await Directory(p.join(badRoot, '.busymark')).create(recursive: true);
    await File(
      p.join(badRoot, '.busymark', 'spelling.json'),
    ).writeAsString('{broken');
    final controller = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
    );
    addTearDown(controller.dispose);
    final settings = AppSettings.defaults().copyWith(
      defaultSpellingLanguage: 'en-Test',
    );
    controller.update(
      _sessionInput(
        id: 'good-buffer',
        root: goodRoot,
        text: 'helo',
        settings: settings,
      ),
    );
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.ready,
    );
    final oldOccurrence = controller.misspellings.single;

    controller.update(
      _sessionInput(
        id: 'bad-buffer',
        root: badRoot,
        text: 'different',
        settings: settings,
      ),
    );
    expect(controller.state.status, SpellingPresentationStatus.checking);
    expect(controller.misspellings, isEmpty);
    expect(controller.occurrenceAtSource(0), isNull);
    expect(controller.isCurrent(oldOccurrence), isFalse);
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.failure,
    );
    expect(controller.misspellings, isEmpty);
    expect(controller.state.message, contains('FormatException'));
  });

  test('external project-word edits refresh an open document', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'busymark-external-words-',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final bundle = await _createFixtureBundle(temporary);
    final root = p.join(temporary.path, 'project');
    final storeFile = File(p.join(root, '.busymark', 'spelling.json'));
    await storeFile.parent.create(recursive: true);
    await storeFile.writeAsString(
      jsonEncode({'schemaVersion': 1, 'revision': 1, 'words': {}}),
    );
    final controller = SpellingSessionController(
      bundledRoot: bundle,
      applicationSupportRoot: p.join(temporary.path, 'support'),
      dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
      verifyDictionaryChecksums: false,
    );
    addTearDown(controller.dispose);
    final settings = AppSettings.defaults().copyWith(
      defaultSpellingLanguage: 'en-Test',
    );
    controller.update(
      _sessionInput(
        id: 'external-words',
        root: root,
        text: 'BusyBrand',
        settings: settings,
      ),
    );
    await _waitFor(
      () => controller.state.status == SpellingPresentationStatus.ready,
    );
    expect(controller.misspellings.single.word, 'BusyBrand');

    await storeFile.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'revision': 2,
        'words': {
          'en-Test': [
            {'key': 'ignored', 'display': 'BusyBrand'},
          ],
        },
      }),
      flush: true,
    );
    await _waitFor(
      () =>
          controller.projectWords.revision == 2 &&
          controller.state.status == SpellingPresentationStatus.ready &&
          controller.misspellings.isEmpty,
    );

    expect(controller.projectWords.wordsFor('en-Test'), ['BusyBrand']);
  });

  testWidgets(
    'review dialog keeps one traversal through skip, back, correction, and persistence',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late final Directory temporary;
      late final SpellingSessionController controller;
      late DocumentBuffer buffer;
      late final AppSettings settings;
      await tester.runAsync(() async {
        temporary = await Directory.systemTemp.createTemp(
          'busymark-review-dialog-',
        );
        final bundle = await _createFixtureBundle(temporary);
        controller = SpellingSessionController(
          bundledRoot: bundle,
          applicationSupportRoot: p.join(temporary.path, 'support'),
          dictionaryStorageRoot: p.join(temporary.path, 'dictionary-storage'),
          verifyDictionaryChecksums: false,
          coordinatorStarter: () => SpellingCoordinator.start(
            suggestionLookup: (_, word) async => switch (word) {
              'helo' => const ['hello'],
              'wrld' => const ['world'],
              _ => const [],
            },
          ),
        );
        buffer = DocumentBuffer.untitled(
          id: 'review-dialog',
          name: 'review.md',
          text: 'helo wrld eror',
        );
        settings = AppSettings.defaults().copyWith(
          defaultSpellingLanguage: 'en-Test',
        );
        await controller.checkNow(
          SpellingSessionInput(
            buffer: buffer,
            workspace: null,
            settings: settings,
            documentKind: DocumentKind.markdown,
            markdownMode: MarkdownMode.commonMark,
          ),
        );
      });
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      addTearDown(controller.dispose);
      SpellingSessionInput input() => SpellingSessionInput(
        buffer: buffer,
        workspace: null,
        settings: settings,
        documentKind: DocumentKind.markdown,
        markdownMode: MarkdownMode.commonMark,
      );
      expect(controller.misspellings.map((item) => item.word), [
        'helo',
        'wrld',
        'eror',
      ]);
      final reveals = <String>[];
      final l10n = AppLocalizationsEn();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => BusyMarkSpellingReviewDialog(
                  spelling: controller,
                  initialIndex: 0,
                  onReveal: (occurrence) => reveals.add(occurrence.word),
                  onCorrect: (occurrence, suggestion) {
                    final start = occurrence.sourceStart!;
                    final end = occurrence.sourceEnd!;
                    buffer = buffer.copyWith(
                      text: buffer.text.replaceRange(start, end, suggestion),
                      revision: buffer.revision + 1,
                    );
                    return true;
                  },
                  onChooseLanguage: () async => false,
                ),
              ),
              child: const Text('Open review'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open review'));
      await _pumpWidgetUntil(
        tester,
        () => find.text('helo').evaluate().isNotEmpty,
      );
      expect(find.text('helo'), findsOneWidget);

      await tester.tap(find.text(l10n.sourceSearchNextMatch));
      await tester.pump();
      expect(find.text('wrld'), findsOneWidget);
      await tester.tap(find.text(l10n.sourceSearchPreviousMatch));
      await tester.pump();
      expect(find.text('helo'), findsOneWidget);

      await tester.tap(find.text(l10n.ignoreSpellingOnce));
      await tester.pump();
      expect(find.text('wrld'), findsOneWidget);
      await _pumpWidgetUntil(
        tester,
        () => find.text('world').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('world'));
      await tester.runAsync(() => controller.checkNow(input()));
      await tester.pump();
      await _pumpWidgetUntil(
        tester,
        () => find.text('eror').evaluate().isNotEmpty,
      );
      expect(buffer.text, 'helo world eror');
      expect(reveals, contains('eror'));

      final erorOccurrence = controller.misspellings.singleWhere(
        (occurrence) => occurrence.word == 'eror',
      );
      expect(controller.isCurrent(erorOccurrence), isTrue);
      final addPersonal = find.text(l10n.addPersonalSpellingWord);
      await tester.ensureVisible(addPersonal);
      await tester.tap(addPersonal);
      await tester.pump();
      await _pumpWidgetUntil(
        tester,
        () =>
            controller.personalWords.wordsFor('en-Test').contains('eror') &&
            find.text(l10n.checkSpelling).evaluate().isEmpty,
      );
      expect(controller.personalWords.wordsFor('en-Test'), contains('eror'));
      controller.endManualReview();
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpWidgetUntil(
        tester,
        () => controller.state.status == SpellingPresentationStatus.ready,
      );
    },
  );

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

    test('catalog validation requires its resource-specific probe', () async {
      final fixture = p.join(
        Directory.current.path,
        'packages',
        'busymark_spellcheck_native',
        'test',
        'fixtures',
      );
      final affPath = p.join(fixture, 'test.aff');
      final dicPath = p.join(fixture, 'test.dic');

      expect(
        await worker.validateDictionary(
          affPath: affPath,
          dicPath: dicPath,
          knownValidProbe: 'hello',
        ),
        'UTF-8',
      );
      await expectLater(
        worker.validateDictionary(
          affPath: affPath,
          dicPath: dicPath,
          knownValidProbe: 'definitelynotaword',
        ),
        throwsA(isA<StateError>()),
      );
    });

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

    test('isolates encoding and oversized-token failures', () async {
      final temporary = await Directory.systemTemp.createTemp(
        'busymark-token-failures-',
      );
      addTearDown(() async {
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
      final aff = File(p.join(temporary.path, 'latin.aff'));
      final dic = File(p.join(temporary.path, 'latin.dic'));
      await aff.writeAsString(
        'SET ISO8859-1\nTRY abcdefghijklmnopqrstuvwxyz\n',
      );
      await dic.writeAsString('1\nhello\n');
      final context = SpellingEngineContext(
        languageId: 'en-Test',
        affPath: aff.path,
        dicPath: dic.path,
        baseFingerprint: 'latin-fixture',
        personalRevision: 0,
        projectIdentity: 'token-failures',
        projectRevision: 0,
        customWords: const [],
      );

      final encodingText = 'helo Ελληνικά helo';
      final encodingResult = await worker.check(
        context: context,
        runs: [_run(encodingText)],
      );
      expect(encodingResult.complete, isFalse);
      expect(
        encodingResult.occurrences
            .where((item) => item.outcome == SpellingCheckOutcome.rejected)
            .map((item) => item.word),
        ['helo', 'helo'],
      );
      expect(
        encodingResult.occurrences
            .singleWhere(
              (item) => item.outcome == SpellingCheckOutcome.unchecked,
            )
            .word,
        'Ελληνικά',
      );

      final oversized = 'x' * (70 * 1024);
      final oversizedText = 'helo $oversized helo';
      final oversizedResult = await worker.check(
        context: context,
        runs: [_run(oversizedText)],
      );
      expect(oversizedResult.complete, isFalse);
      expect(
        oversizedResult.occurrences
            .where((item) => item.outcome == SpellingCheckOutcome.rejected)
            .map((item) => item.word),
        ['helo', 'helo'],
      );
      final unchecked = oversizedResult.occurrences.singleWhere(
        (item) => item.outcome == SpellingCheckOutcome.unchecked,
      );
      expect(unchecked.word.length, oversized.length);
      expect(unchecked.logicalStart, 'helo '.length);
      expect(unchecked.logicalEnd, 'helo '.length + oversized.length);
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

SpellingSessionInput _sessionInput({
  required String id,
  required String root,
  required String text,
  required AppSettings settings,
  int revision = 0,
}) {
  var buffer = DocumentBuffer.untitled(id: id, name: '$id.md', text: text);
  if (revision != 0) buffer = buffer.copyWith(revision: revision);
  return SpellingSessionInput(
    buffer: buffer,
    workspace: Workspace(
      id: 'workspace-$id',
      rootPath: root,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      files: const [],
      diagnostics: const [],
    ),
    settings: settings,
    documentKind: DocumentKind.markdown,
    markdownMode: MarkdownMode.commonMark,
  );
}

SpellingWordStoreSnapshot _wordSnapshot(String word) =>
    SpellingWordStoreSnapshot(
      revision: 1,
      wordsByLanguage: {
        'en-Test': [SpellingWordEntry(key: word, display: word)],
      },
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
          'knownValidProbe': 'hello',
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

Future<({String bundle, String aff, String dic})> _createAliasedFixtureBundle(
  Directory temporary,
) async {
  final fixture = p.join(
    Directory.current.path,
    'packages',
    'busymark_spellcheck_native',
    'test',
    'fixtures',
  );
  final aff = File(p.join(fixture, 'test.aff'));
  final dic = File(p.join(fixture, 'test.dic'));
  final affChecksum = await sha256.bind(aff.openRead()).first;
  final dicChecksum = await sha256.bind(dic.openRead()).first;
  final bundle = Directory(p.join(temporary.path, 'alias-bundle'));
  await bundle.create(recursive: true);
  await File(p.join(bundle.path, 'dictionaries.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 2,
      'dictionaries': [
        {
          'resourceId': 'nl-AW',
          'id': 'nl-AW',
          'knownValidProbe': 'hello',
          'locales': ['nl-AW', 'nl-NL'],
          'label': 'Dutch',
          'affSourcePath': 'nl/test.aff',
          'dicSourcePath': 'nl/test.dic',
          'affDownloadUrl': 'https://example.invalid/test.aff',
          'dicDownloadUrl': 'https://example.invalid/test.dic',
          'affSize': await aff.length(),
          'dicSize': await dic.length(),
          'sourceRevision': 'fixture',
          'affSha256': affChecksum.toString(),
          'dicSha256': dicChecksum.toString(),
        },
      ],
    }),
  );
  final installed = Directory(
    p.join(temporary.path, 'dictionary-storage', 'downloaded', 'nl-AW'),
  );
  await installed.create(recursive: true);
  await aff.copy(p.join(installed.path, 'dictionary.aff'));
  await dic.copy(p.join(installed.path, 'dictionary.dic'));
  await File(p.join(installed.path, 'manifest.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'kind': 'downloaded',
      'resourceId': 'nl-AW',
      'id': 'nl-AW',
      'locales': ['nl-AW', 'nl-NL'],
      'label': 'Dutch',
      'sourceRevision': 'fixture',
      'affPath': 'dictionary.aff',
      'dicPath': 'dictionary.dic',
      'affSha256': affChecksum.toString(),
      'dicSha256': dicChecksum.toString(),
    }),
  );
  return (bundle: bundle.path, aff: aff.path, dic: dic.path);
}

Map<String, Object?> _resourceJson(SpellingDictionaryResource resource) => {
  'resourceId': resource.resourceId,
  'id': resource.id,
  'knownValidProbe': resource.knownValidProbe,
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

Future<void> _pumpWidgetUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final watch = Stopwatch()..start();
  while (!predicate()) {
    if (watch.elapsed > timeout) {
      throw TimeoutException('Timed out waiting for spelling widget state.');
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

final class _DelayedAtomicFileWriter extends AtomicFileWriter {
  _DelayedAtomicFileWriter();

  final Completer<void> started = Completer<void>();
  final Completer<void> _release = Completer<void>();

  void releaseIfNeeded() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<void> writeBytes(
    String targetPath,
    List<int> bytes, {
    required bool overwrite,
  }) async {
    if (!started.isCompleted) started.complete();
    await _release.future;
    await super.writeBytes(targetPath, bytes, overwrite: overwrite);
  }
}
