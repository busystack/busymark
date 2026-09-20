import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../markdown/markdown_model.dart';
import '../workspace/document_buffer.dart';
import '../workspace/workspace_model.dart';
import 'markdown_spelling_projection.dart';
import 'spelling_catalog.dart';
import 'spelling_projection.dart';
import 'spelling_replacement.dart';
import 'spelling_word_store.dart';
import 'spelling_worker.dart';

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

/// Exercises spelling through the installed executable and bundle.
///
/// This deliberately resolves no host dictionary path. It covers the bundled
/// native asset, real dictionary, source projection, exact correction plan,
/// document history selections, and application-support word persistence.
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
    final catalog = await SpellingDictionaryCatalog.load(
      bundledRoot: bundledRoot,
      verifyChecksums: true,
    );
    checks['dictionaryCount'] = catalog.entries.length;
    final english = catalog.byId('en-US');
    if (english == null) {
      throw StateError('The installed en-US dictionary is unavailable.');
    }

    const source = 'This is helo.\n';
    const bufferId = 'spelling-release-smoke';
    const snapshot = SpellingSnapshotIdentity(
      bufferId: bufferId,
      contentRevision: 0,
      documentKind: DocumentKind.markdown,
      contextGeneration: 1,
    );
    final projection = const MarkdownSpellingProjector().project(
      filePath: '/spelling-release-smoke.md',
      source: source,
      mode: MarkdownMode.gfm,
      languageId: 'en-US',
      snapshot: snapshot,
    );
    worker = await SpellingWorker.start();
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

    final plan = const SpellingReplacementPlanner().build(
      occurrence: occurrence,
      suggestion: 'hello',
    );
    final corrected = plan.applyToSource(source);
    if (corrected != 'This is hello.\n') {
      throw StateError('The exact source correction changed unexpected text.');
    }
    final buffer =
        DocumentBuffer.untitled(
          id: bufferId,
          name: 'spelling-release-smoke.md',
          text: source,
        ).copyWith(
          editorState: const DocumentEditorState(
            selection: TextSelection.collapsed(offset: 10),
          ),
        );
    final edited = buffer.edited(
      corrected,
      previousSelection: const TextSelection(baseOffset: 8, extentOffset: 12),
      nextSelection: TextSelection.collapsed(
        offset: plan.resultingSourceCaret ?? 13,
      ),
    );
    final undoTarget = edited.editorState.undoState.undo.single;
    final redoState = edited.editorState.undoState.afterUndo(
      DocumentHistoryState(
        text: edited.text,
        selection: edited.editorState.selection,
      ),
    );
    if (undoTarget.text != source ||
        undoTarget.selection !=
            const TextSelection(baseOffset: 8, extentOffset: 12) ||
        redoState.redo.single.text != corrected ||
        redoState.redo.single.selection != edited.editorState.selection) {
      throw StateError('Correction undo/redo state did not retain selections.');
    }
    checks['correctedSource'] = corrected;
    checks['historyRoundTrip'] = true;

    final support = await getApplicationSupportDirectory();
    final personalFile = p.join(
      support.path,
      'spelling',
      'personal-release-smoke.json',
    );
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

Future<void> _writeReport(File file, Map<String, Object?> report) =>
    file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      flush: true,
    );
