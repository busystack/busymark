import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../../l10n/generated/app_localizations.dart';
import '../core/diagnostic.dart';
import '../editor/source/source_editor.dart';
import '../editor/source/source_search.dart';
import '../editor/source_language.dart';
import '../editor/wysiwyg/wysiwyg_editor.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import 'markdown_spelling_projection.dart';
import 'spelling_catalog.dart';
import 'spelling_coordinator.dart';
import 'spelling_dictionary_downloader.dart';
import 'spelling_projection.dart';
import 'spelling_replacement.dart';
import 'spelling_session_controller.dart';
import 'spelling_word_store.dart';
import 'spelling_worker.dart';
import 'wysiwyg_spelling_projection.dart';

const spellingReleaseSmokeArgument = '--spelling-release-smoke=';

String? spellingReleaseSmokeReportPath(
  Iterable<String> arguments, {
  Map<String, String>? environment,
}) {
  if ((environment ?? Platform.environment)['BUSYMARK_RELEASE_SMOKE'] != '1') {
    return null;
  }
  for (final argument in arguments) {
    if (!argument.startsWith(spellingReleaseSmokeArgument)) continue;
    final path = argument.substring(spellingReleaseSmokeArgument.length);
    return path.trim().isEmpty ? null : path;
  }
  return null;
}

/// Exercises spelling through the installed executable, editor widgets, and
/// bundle.
///
/// This deliberately resolves no host dictionary path. It covers the bundled
/// native asset, real dictionary, Source and WYSIWYG transaction paths,
/// workspace undo/redo, and the normal personal-word storage path.
Future<int> runSpellingReleaseSmoke(String reportPath) async {
  final reportFile = File(p.normalize(p.absolute(reportPath)));
  await reportFile.parent.create(recursive: true);
  SpellingWorker? worker;
  final checks = <String, Object?>{};
  try {
    final bundledRoot = const SpellingResourceLocator().locate();
    if (bundledRoot == null) {
      throw StateError('Installed spelling resources were not found.');
    }
    checks['resourceRoot'] = bundledRoot;
    await _verifyInstalledSpellingInventory(bundledRoot);
    checks['resourceChecksumInventory'] = true;
    final nativeNoticeRoot = Directory(
      p.normalize(
        p.join(bundledRoot, '..', '..', 'licenses', 'busymark-spellcheck'),
      ),
    );
    for (final relative in [
      'Apache-2.0.txt',
      'DEPENDENCIES.md',
      p.join('hunspell', 'COPYING'),
      p.join('hunspell', 'COPYING.LESSER'),
      p.join('hunspell', 'COPYING.MPL'),
      p.join('hunspell', 'license.hunspell'),
      p.join('hunspell', 'license.myspell'),
    ]) {
      if (!await File(p.join(nativeNoticeRoot.path, relative)).exists()) {
        throw StateError(
          'Installed native dependency notice is missing: $relative',
        );
      }
    }
    checks['nativeDependencyNotices'] = true;
    final catalog = await SpellingDictionaryCatalog.load(
      bundledRoot: bundledRoot,
      verifyChecksums: true,
    );
    checks['availableDictionaryCount'] = catalog.availableEntries.length;
    final bundledPairs = await Directory(bundledRoot)
        .list(recursive: true)
        .where(
          (entity) =>
              entity is File &&
              (entity.path.endsWith('.aff') || entity.path.endsWith('.dic')),
        )
        .length;
    checks['bundledDictionaryFileCount'] = bundledPairs;
    if (bundledPairs != 0) {
      throw StateError('The installed package contains language pairs.');
    }
    final englishResource = catalog.availableById('en-US');
    if (englishResource == null) {
      throw StateError('The en-US resource is absent from the catalog.');
    }
    final support = await getApplicationSupportDirectory();
    final dictionaryRoot = resolveSpellingDictionaryStorageRoot(
      applicationSupportRoot: support.path,
    );
    final downloadedRoot = p.join(dictionaryRoot, 'downloaded');
    worker = await SpellingWorker.start();
    var installedDuringRun = false;
    var installedCatalog = await SpellingDictionaryCatalog.load(
      bundledRoot: bundledRoot,
      downloadedRoot: downloadedRoot,
    );
    if (installedCatalog.installedById('en-US') == null) {
      await const SpellingDictionaryDownloader().install(
        resource: englishResource,
        downloadedRoot: downloadedRoot,
        validateNativePair: (aff, dic, probe) => worker!.validateDictionary(
          affPath: aff,
          dicPath: dic,
          knownValidProbe: probe,
        ),
        cancellation: SpellingDictionaryDownloadCancellation(),
        onProgress: (_, _) {},
      );
      installedDuringRun = true;
      installedCatalog = await SpellingDictionaryCatalog.load(
        bundledRoot: bundledRoot,
        downloadedRoot: downloadedRoot,
      );
    }
    final english = installedCatalog.installedById('en-US');
    if (english == null) {
      throw StateError('The installed en-US dictionary is unavailable.');
    }
    checks['dictionaryInstalledDuringRun'] = installedDuringRun;
    checks['installedDictionaryCount'] = installedCatalog.installations.length;
    if (installedCatalog.installations.length != 1) {
      throw StateError('The smoke profile did not contain exactly one pair.');
    }

    const source = 'This is helo.\n';
    final container = ProviderContainer();
    final workspace = container.read(workspaceControllerProvider.notifier);
    await workspace.createMarkdownFile();
    workspace.updateActiveText(source);
    var buffer = container.read(workspaceControllerProvider).activeBuffer!;
    final snapshot = SpellingSnapshotIdentity(
      bufferId: buffer.id,
      contentRevision: buffer.revision,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    final projection = const MarkdownSpellingProjector().project(
      filePath: buffer.id,
      source: source,
      mode: MarkdownMode.gfm,
      languageId: 'en-US',
      snapshot: snapshot,
    );
    final context = SpellingEngineContext(
      languageId: english.id,
      affPath: english.affPath,
      dicPath: english.dicPath,
      baseFingerprint: english.fingerprint,
      personalRevision: 0,
      projectIdentity: null,
      projectRevision: 0,
      customWords: const [],
    );
    final checked = await worker.check(context: context, runs: projection.runs);
    final occurrence = checked.occurrences.singleWhere(
      (candidate) =>
          candidate.word == 'helo' &&
          candidate.outcome == SpellingCheckOutcome.rejected,
    );
    final suggestions = await worker.suggestions(
      context: context,
      word: occurrence.word,
    );
    if (!suggestions.contains('hello')) {
      throw StateError('The installed dictionary did not suggest hello.');
    }
    checks['rejectedWord'] = occurrence.word;
    checks['suggestion'] = 'hello';

    final preparedSource = await prepareSpellingCorrection(
      occurrence: occurrence,
      suggestion: 'hello',
      source: source,
    );
    final corrected = preparedSource.replacementSource!;
    if (corrected != 'This is hello.\n') {
      throw StateError('The exact source correction changed unexpected text.');
    }
    final sourceKey = GlobalKey<BusyMarkSourceEditorState>();
    await _mountSmokeEditor(
      BusyMarkSourceEditor(
        key: sourceKey,
        text: source,
        language: SourceSyntaxLanguage.markdown,
        filePath: null,
        documentId: buffer.id,
        diagnostics: const <Diagnostic>[],
        editorFontSize: 14,
        wordWrap: true,
        searchActive: false,
        searchOptions: const SourceSearchOptions(),
        onSearchOptionsChanged: (_) {},
        onChanged: (_, _) {},
        onTransactionalChanged:
            (text, sourceFilePath, previousSelection, selection, undoGroup) =>
                workspace.updateActiveSourceText(
                  text,
                  sourceFilePath: sourceFilePath,
                  previousSelection: previousSelection,
                  selection: selection,
                  undoGroup: undoGroup,
                ),
        onOpenSearch: () {},
        onCloseSearch: () {},
        editRevision: buffer.revision,
        initialSelection: const TextSelection(baseOffset: 8, extentOffset: 12),
        spellingAnnotations: [_annotationFor(occurrence)],
      ),
    );
    if (sourceKey.currentState?.applyPreparedSpellingCorrection(
          occurrence: occurrence,
          plan: preparedSource.plan,
          expectedSource: source,
          replacementSource: corrected,
        ) !=
        true) {
      throw StateError('The installed Source editor rejected the correction.');
    }
    await _settleSmokeFrames();
    buffer = container.read(workspaceControllerProvider).activeBuffer!;
    if (buffer.text != corrected ||
        buffer.editorState.selection !=
            const TextSelection.collapsed(offset: 13)) {
      throw StateError('The Source editor did not publish its transaction.');
    }
    if (!workspace.undoActiveBuffer() ||
        container.read(workspaceControllerProvider).activeBuffer?.text !=
            source ||
        container
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.editorState
                .selection !=
            const TextSelection(baseOffset: 8, extentOffset: 12) ||
        !workspace.redoActiveBuffer() ||
        container.read(workspaceControllerProvider).activeBuffer?.text !=
            corrected ||
        container
                .read(workspaceControllerProvider)
                .activeBuffer
                ?.editorState
                .selection !=
            const TextSelection.collapsed(offset: 13)) {
      throw StateError(
        'Workspace undo/redo did not retain the Source correction selection.',
      );
    }
    checks['correctedSource'] = corrected;
    checks['sourceEditorTransaction'] = true;
    checks['workspaceHistoryRoundTrip'] = true;

    await _exerciseRichEditor(
      container: container,
      workspace: workspace,
      worker: worker,
      context: context,
      source: '**helo**\n',
      expected: '**hello**\n',
      expectedTarget: SpellingRichBlockTarget,
    );
    checks['formattedRichEditorTransaction'] = true;
    await _exerciseRichEditor(
      container: container,
      workspace: workspace,
      worker: worker,
      context: context,
      source: '| Heading |\n| --- |\n| helo |\n',
      expected: '| Heading |\n| --- |\n| hello |\n',
      expectedTarget: SpellingRichTableCellTarget,
    );
    checks['tableCellEditorTransaction'] = true;

    final personalFile = p.join(support.path, 'spelling', 'personal.json');
    final store = SpellingWordStore(filePath: personalFile);
    final before = await store.read();
    final hadPersistedWord = before
        .wordsFor('en-US')
        .contains('BusyMarkReleaseTerm');
    await store.addWord('en-US', 'BusyMarkReleaseTerm');
    final restarted = await SpellingWordStore(filePath: personalFile).read();
    if (!restarted.wordsFor('en-US').contains('BusyMarkReleaseTerm')) {
      throw StateError('The personal word did not survive store restart.');
    }
    checks['personalWordPersisted'] = true;
    checks['personalWordPresentBeforeRun'] = hadPersistedWord;

    await _unmountSmokeEditor();
    container.dispose();

    await _writeReport(reportFile, {'ok': true, 'checks': checks});
    return 0;
  } on Object catch (error, stackTrace) {
    await _writeReport(reportFile, {
      'ok': false,
      'checks': checks,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
    return 1;
  } finally {
    await worker?.close();
  }
}

Future<void> _verifyInstalledSpellingInventory(String root) async {
  final inventory = File(p.join(root, 'CHECKSUMS.sha256'));
  if (!await inventory.exists()) {
    throw StateError('Installed spelling checksum inventory is missing.');
  }
  for (final line in await inventory.readAsLines()) {
    if (line.trim().isEmpty) continue;
    final match = RegExp(r'^([0-9a-f]{64})  (.+)$').firstMatch(line);
    if (match == null) {
      throw StateError('Installed spelling checksum inventory is malformed.');
    }
    final file = File(p.join(root, match.group(2)!));
    if (!await file.exists() ||
        (await sha256.bind(file.openRead()).first).toString() !=
            match.group(1)) {
      throw StateError(
        'Installed spelling resource failed checksum: ${match.group(2)}',
      );
    }
  }
}

Future<void> _exerciseRichEditor({
  required ProviderContainer container,
  required WorkspaceController workspace,
  required SpellingWorker worker,
  required SpellingEngineContext context,
  required String source,
  required String expected,
  required Type expectedTarget,
}) async {
  workspace.updateActiveText(source);
  final buffer = container.read(workspaceControllerProvider).activeBuffer!;
  final document = const MarkdownParser()
      .parse(
        filePath: buffer.id,
        source: source,
        mode: MarkdownMode.commonMark,
        validateLocalReferences: false,
      )
      .busyDocument;
  final snapshot = SpellingSnapshotIdentity(
    bufferId: buffer.id,
    contentRevision: buffer.revision,
    documentKind: DocumentKind.markdown,
    contextGeneration: 1,
  );
  final projection = const WysiwygSpellingProjector().project(
    document: document,
    languageId: context.languageId,
    snapshot: snapshot,
    documentGeneration: 0,
  );
  if (!projection.complete) {
    throw StateError(projection.message ?? 'Rich projection was incomplete.');
  }
  final checked = await worker.check(context: context, runs: projection.runs);
  final occurrence = checked.occurrences.singleWhere(
    (candidate) =>
        candidate.word == 'helo' &&
        candidate.run.target.runtimeType == expectedTarget,
  );
  final key = GlobalKey<BusyMarkWysiwygEditorState>();
  var publishedDocument = document;
  await _mountSmokeEditor(
    BusyMarkWysiwygEditor(
      key: key,
      document: document,
      documentId: buffer.id,
      contentRevision: buffer.revision,
      useExternalUndoHistory: true,
      spellingAnnotations: [_annotationFor(occurrence)],
      onDocumentChanged: (value) => publishedDocument = value,
      onSourceChanged: (_, _) {},
      onSpellingSourceChanged: (_, value, before, after) =>
          workspace.updateActiveWysiwygText(
            value,
            document: publishedDocument,
            previousWysiwygState: before,
            wysiwygState: after,
          ),
    ),
  );
  final field = key.currentState?.spellingFieldSnapshot(occurrence);
  if (field == null) {
    throw StateError('The installed rich editor did not expose its field.');
  }
  final prepared = await prepareSpellingCorrection(
    occurrence: occurrence,
    suggestion: 'hello',
    field: field,
  );
  if (key.currentState?.applyPreparedSpellingCorrection(
        occurrence: occurrence,
        suggestion: 'hello',
        plan: prepared.plan,
        expectedFieldText: field,
        preparedFieldText: prepared.replacementField,
      ) !=
      true) {
    throw StateError('The installed rich editor rejected a correction.');
  }
  await _settleSmokeFrames();
  if (container.read(workspaceControllerProvider).activeBuffer?.text !=
      expected) {
    throw StateError('The rich correction changed unexpected source.');
  }
  if (!workspace.undoActiveBuffer() ||
      container.read(workspaceControllerProvider).activeBuffer?.text !=
          source ||
      !workspace.redoActiveBuffer() ||
      container.read(workspaceControllerProvider).activeBuffer?.text !=
          expected) {
    throw StateError('Rich editor correction failed workspace undo/redo.');
  }
}

SpellingAnnotation _annotationFor(SpellingOccurrence occurrence) =>
    SpellingAnnotation(
      occurrenceId: occurrence.id,
      start: occurrence.run.target is SpellingSourceTarget
          ? occurrence.sourceStart!
          : occurrence.fieldStart!,
      end: occurrence.run.target is SpellingSourceTarget
          ? occurrence.sourceEnd!
          : occurrence.fieldEnd!,
      target: occurrence.run.target,
    );

Future<void> _mountSmokeEditor(Widget editor) async {
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 1000, height: 700, child: editor)),
    ),
  );
  await _settleSmokeFrames();
}

Future<void> _unmountSmokeEditor() async {
  runApp(const SizedBox.shrink());
  await _settleSmokeFrames();
}

Future<void> _settleSmokeFrames() async {
  for (var index = 0; index < 3; index++) {
    await WidgetsBinding.instance.endOfFrame.timeout(
      const Duration(seconds: 5),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _writeReport(File file, Map<String, Object?> report) =>
    file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      flush: true,
    );
