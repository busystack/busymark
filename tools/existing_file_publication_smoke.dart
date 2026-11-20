// Run the Linux bundle or its kernel with an empty directory on the filesystem
// under test. Temporary fixtures are created and removed within that directory.
import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/atomic_file_writer.dart';
import 'package:busymark/src/core/save_destination.dart';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final rootPath =
      Platform.environment['BUSYMARK_PUBLICATION_ROOT'] ?? args.single;
  final root = Directory(rootPath).createTempSync('busymark-publication-');
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_Settings()),
      documentSessionStoreProvider.overrideWithValue(
        MemoryDocumentSessionStore(),
      ),
      documentRecoveryStoreProvider.overrideWithValue(
        MemoryDocumentRecoveryStore(),
      ),
      localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
    ],
  );
  try {
    await _checkPublication(root, container);
  } on Object catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exitCode = 1;
  } finally {
    container.dispose();
    root.deleteSync(recursive: true);
  }
  exit(exitCode);
}

Future<void> _checkPublication(
  Directory root,
  ProviderContainer container,
) async {
  File file(String name, String contents) =>
      File(p.join(root.path, name))..writeAsStringSync(contents, flush: true);

  final first = file('a.md', '# A\n');
  final second = file('b.md', '# B\n');
  final settings = container.read(appSettingsControllerProvider.notifier);
  await settings.setAutoSave(false);
  final controller = container.read(workspaceControllerProvider.notifier);
  await controller.openPath(root.path);
  _check(await controller.openActiveFile(first.path), 'Open first document');
  controller.updateActiveText('# Saved\n');
  if (!await controller.saveActive()) {
    final message = container.read(workspaceControllerProvider).message;
    throw StateError(
      'Save existing document failed: ${message?.code}, ${message?.error}. '
      'Destination bytes: ${first.existsSync() ? first.readAsStringSync() : '<missing>'}',
    );
  }
  _check(true, 'Save existing document');
  _check(first.readAsStringSync() == '# Saved\n', 'Save publishes exact bytes');

  controller.updateActiveText('# Save All A\n');
  _check(await controller.openActiveFile(second.path), 'Open second document');
  controller.updateActiveText('# Save All B\n');
  final all = await controller.saveAll();
  _check(
    all.savedBufferIds.length == 2 && all.succeeded,
    'Save All existing documents',
  );
  _check(
    first.readAsStringSync() == '# Save All A\n' &&
        second.readAsStringSync() == '# Save All B\n',
    'Save All publishes both files',
  );
  await settings.setAutoSave(true);
  controller.updateActiveText('# Autosaved\n');
  _check(
    await controller.autoSaveActiveIfNeeded(),
    'Autosave existing document',
  );
  _check(
    second.readAsStringSync() == '# Autosaved\n',
    'Autosave publishes exact bytes',
  );
  await settings.setAutoSave(false);
  await controller.flushPersistence();

  final html = file('replacement.html', 'previous HTML');
  await const HtmlExportService().exportMarkdown(
    MarkdownHtmlExportRequest(
      source: '# Published HTML',
      filePath: first.path,
      workspaceRoot: root.path,
      destinationPath: html.path,
      overwrite: true,
      authorization: SaveDestination.inspect(html.path),
    ),
  );
  _check(
    html.readAsStringSync().contains('Published HTML'),
    'HTML replacement',
  );

  final pdf = file('replacement.pdf', 'previous PDF');
  final pdfRequest = MarkdownPdfExportRequest(
    source: '# Published PDF',
    filePath: first.path,
    workspaceRoot: root.path,
    destinationPath: pdf.path,
    overwrite: true,
    authorization: SaveDestination.inspect(pdf.path),
    options: const PdfExportOptions(),
  );
  const pdfExporter = MarkdownPdfExportService();
  final cancellation = MarkdownPdfCancellationToken()..cancel();
  try {
    await pdfExporter.export(pdfRequest, cancellationToken: cancellation);
    throw StateError('Cancelled export published');
  } on MarkdownPdfExportException catch (error) {
    _check(error.code == MarkdownPdfFailureCode.cancelled, 'PDF cancellation');
  }
  _check(
    pdf.readAsStringSync() == 'previous PDF',
    'Cancelled export preserves PDF',
  );
  await pdfExporter.export(pdfRequest);
  _check(
    ascii.decode(pdf.readAsBytesSync().take(5).toList()) == '%PDF-',
    'PDF replacement',
  );

  final diagram = file('replacement.svg', 'previous diagram');
  const writer = AtomicFileWriter();
  await writer.writeBytes(
    diagram.path,
    utf8.encode('<svg/>'),
    overwrite: true,
    authorization: SaveDestination.inspect(diagram.path),
  );
  _check(diagram.readAsStringSync() == '<svg/>', 'Diagram replacement');

  final raced = file('raced.md', 'original');
  const service = WorkspaceService();
  final expected = await service.fileSnapshot(raced.path);
  final interveningWriter = WorkspaceService(
    beforeDisplacedValidation: (target, _) async {
      File(target).writeAsStringSync('concurrent writer', flush: true);
      throw const FileSystemException('injected validation failure');
    },
  );
  try {
    await interveningWriter.saveTextIfUnchanged(
      raced.path,
      'should not replace a concurrent file',
      expectedSnapshot: expected,
    );
    throw StateError('Concurrent modification was accepted');
  } on AtomicFileChangedException catch (error) {
    _check(
      raced.readAsStringSync() == 'concurrent writer',
      'Concurrent file survives',
    );
    _check(
      error.recoveryPath != null &&
          File(error.recoveryPath!).readAsStringSync() == 'original',
      'Displaced original survives an intervening publication',
    );
  }

  final failing = file('failed.md', 'original');
  final failingWriter = WorkspaceService(
    beforeDisplacedValidation: (_, _) async {
      throw const FileSystemException('injected validation failure');
    },
  );
  try {
    await failingWriter.saveTextIfUnchanged(
      failing.path,
      'partial write',
      expectedSnapshot: await service.fileSnapshot(failing.path),
    );
    throw StateError('Injected failure unexpectedly succeeded');
  } on AtomicFileChangedException {
    _check(
      failing.readAsStringSync() == 'original',
      'Failed validation restores original',
    );
  }
}

void _check(bool succeeded, String operation) {
  if (!succeeded) throw StateError('$operation failed');
  stdout.writeln('PASS $operation');
}

class _Settings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async =>
      AppSettings.defaults().copyWith(autoSave: false).toJson();

  @override
  Future<void> save(Map<String, Object?> json) async {}
}
