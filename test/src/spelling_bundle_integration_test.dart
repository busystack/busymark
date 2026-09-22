import 'dart:io';

import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_html.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/spelling_catalog.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_worker.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark_spellcheck_native/busymark_spellcheck_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Platform.environment['BUSYMARK_TEST_SPELLING_ROOT'];
  final unavailable =
      root == null || !File('$root/dictionaries.json').existsSync();

  test(
    'real en-CA checks pasted rich content completely in both editors',
    () async {
      final catalog = await SpellingDictionaryCatalog.load(
        bundledRoot: root!,
        downloadedRoot: '$root/installed',
      );
      final installation = catalog.installedById('en-CA')!;
      final html = await File(
        'test/fixtures/spelling/pasted_job.html',
      ).readAsString();
      final target = const MarkdownParser()
          .parse(
            filePath: '/pasted.md',
            source: 'Target\n',
            mode: MarkdownMode.gfm,
          )
          .busyDocument;
      final editor = BusyMarkWysiwygDocumentController(document: target);
      addTearDown(editor.dispose);
      final fragment = const WysiwygClipboardHtml().decode(
        html,
        mode: MarkdownMode.gfm,
      )!;
      editor.insertStyledBlocksAtSelection(
        blockId: target.blocks.first.id,
        selectionStart: 0,
        selectionEnd: 6,
        blocks: fragment.blocks,
      );
      final source = editor.markdown;
      final document = editor.document.copyWith(source: source);
      final worker = await SpellingWorker.start();
      addTearDown(worker.close);
      const snapshot = SpellingSnapshotIdentity(
        bufferId: 'pasted-job',
        contentRevision: 1,
        documentKind: DocumentKind.markdown,
        contextGeneration: 1,
      );
      for (final rich in [false, true]) {
        final projection = await worker.project(
          SpellingProjectionJob(
            filePath: '/pasted.md',
            source: source,
            documentKind: DocumentKind.markdown,
            markdownMode: MarkdownMode.gfm,
            languageId: 'en-CA',
            snapshot: snapshot,
            richDocument: rich ? document : null,
            richDocumentGeneration: 1,
          ),
        );
        final result = await worker.check(
          context: SpellingEngineContext(
            languageId: 'en-CA',
            affPath: installation.affPath,
            dicPath: installation.dicPath,
            baseFingerprint: installation.fingerprint,
            personalRevision: 0,
            projectIdentity: null,
            projectRevision: 0,
            customWords: const [],
          ),
          runs: projection.runs,
        );
        expect(projection.complete, isTrue, reason: projection.message);
        expect(result.complete, isTrue, reason: result.error);
        final occurrence = result.occurrences.singleWhere(
          (o) => o.word == 'helo',
        );
        expect(occurrence.outcome, SpellingCheckOutcome.rejected);
        expect(occurrence.sourceStart, source.indexOf('helo'));
        if (rich) {
          expect(occurrence.run.target, isA<SpellingRichBlockTarget>());
          final target = occurrence.run.target as SpellingRichBlockTarget;
          final block = document.blocks.singleWhere(
            (block) => block.id == target.blockId,
          );
          expect(occurrence.fieldStart, block.plainText.indexOf('helo'));
          expect(occurrence.fieldEnd! - occurrence.fieldStart!, 4);
        }
      }
    },
    skip: unavailable ? 'Prepared spelling bundle is not available.' : false,
  );

  test(
    'packaged catalog opens real regional and non-Latin dictionaries',
    () async {
      final catalog = await SpellingDictionaryCatalog.load(
        bundledRoot: root!,
        downloadedRoot: '$root/installed',
      );
      expect(catalog.unavailableEntries, isEmpty);
      expect(catalog.availableEntries, hasLength(48));
      expect(catalog.installations, hasLength(48));

      for (final resource in catalog.availableEntries) {
        final installation = catalog.installationForResource(
          resource.resourceId,
        );
        expect(installation, isNotNull, reason: resource.resourceId);
        late final NativeSpellDictionary dictionary;
        try {
          dictionary = NativeSpellDictionary.open(
            affPath: installation!.affPath,
            dicPath: installation.dicPath,
          );
        } on Object catch (error) {
          fail('${resource.resourceId} failed native validation: $error');
        }
        try {
          expect(dictionary.encoding, isNotEmpty, reason: resource.resourceId);
          expect(
            dictionary.check(resource.knownValidProbe),
            NativeSpellResult.accepted,
            reason: '${resource.resourceId}: ${resource.knownValidProbe}',
          );
        } finally {
          dictionary.close();
        }
      }

      final us = _open(catalog, 'en-US');
      try {
        expect(us.check('color'), NativeSpellResult.accepted);
        expect(us.check('helo'), NativeSpellResult.rejected);
        expect(us.suggest('helo'), contains('hello'));
      } finally {
        us.close();
      }
    },
    skip: unavailable ? 'Prepared spelling bundle is not available.' : false,
  );

  test('real en-CA checks the general Markdown fixture completely', () async {
    final catalog = await SpellingDictionaryCatalog.load(
      bundledRoot: root!,
      downloadedRoot: '$root/installed',
    );
    final installation = catalog.installedById('en-CA')!;
    final source = await File('test/fixtures/markdown/basic.md').readAsString();
    final worker = await SpellingWorker.start();
    addTearDown(worker.close);
    const snapshot = SpellingSnapshotIdentity(
      bufferId: 'basic-markdown-fixture',
      contentRevision: 0,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    for (final rich in [false, true]) {
      final document = const MarkdownParser()
          .parse(
            filePath: 'test/fixtures/markdown/basic.md',
            source: source,
            mode: MarkdownMode.gfm,
          )
          .busyDocument;
      final projection = await worker.project(
        SpellingProjectionJob(
          filePath: 'test/fixtures/markdown/basic.md',
          source: source,
          documentKind: DocumentKind.markdown,
          markdownMode: MarkdownMode.gfm,
          languageId: 'en-CA',
          snapshot: snapshot,
          richDocument: rich ? document : null,
          richDocumentGeneration: 1,
        ),
      );
      final result = await worker.check(
        context: SpellingEngineContext(
          languageId: 'en-CA',
          affPath: installation.affPath,
          dicPath: installation.dicPath,
          baseFingerprint: installation.fingerprint,
          personalRevision: 0,
          projectIdentity: null,
          projectRevision: 0,
          customWords: const [],
        ),
        runs: projection.runs,
      );

      expect(projection.complete, isTrue, reason: projection.message);
      expect(
        projection.runs.where((run) => run.text.contains('record Document')),
        isEmpty,
        reason: 'Quoted fenced code must not become spelling prose.',
      );
      expect(result.complete, isTrue, reason: result.error);
      expect(result.error, isNull);
    }
  }, skip: unavailable ? 'Prepared spelling bundle is not available.' : false);
}

NativeSpellDictionary _open(SpellingDictionaryCatalog catalog, String id) {
  final entry = catalog.installedById(id)!;
  return NativeSpellDictionary.open(
    affPath: entry.affPath,
    dicPath: entry.dicPath,
  );
}
