// Builds a disposable native UI verification target for Clipboard History and
// Local History. The target drives the production controllers and widgets; it
// does not replace them with screenshot-only fixtures.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_history_panel.dart';
import 'package:busymark/src/clipboard/clipboard_models.dart';
import 'package:busymark/src/comparison/source_comparison.dart';
import 'package:busymark/src/git/application/git_controller.dart';
import 'package:busymark/src/git/data/git_cli_gateway.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_panel.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (arguments.length != 5) {
    stderr.writeln(
      'Usage: markdown|writerside WORKSPACE PRIMARY_FILE DELETE_FILE_OR_DASH '
      'OUTPUT_DIRECTORY',
    );
    exit(2);
  }
  final mode = arguments[0];
  if (mode != 'markdown' && mode != 'writerside') {
    stderr.writeln('The mode must be markdown or writerside.');
    exit(2);
  }
  final workspacePath = p.normalize(p.absolute(arguments[1]));
  final primaryPath = p.normalize(p.absolute(arguments[2]));
  final deletePath = arguments[3] == '-'
      ? null
      : p.normalize(p.absolute(arguments[3]));
  final output = Directory(p.normalize(p.absolute(arguments[4])));
  await output.create(recursive: true);

  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  final settings = AppSettings.defaults().copyWith(
    themeModePreference: mode == 'writerside'
        ? BusyMarkThemeModePreference.dark
        : BusyMarkThemeModePreference.light,
    localeTag: mode == 'writerside' ? 'ar' : 'en',
    documentViewMode: DocumentViewModePreference.editor,
    previewVisible: false,
    editorFontSize: mode == 'writerside' ? 20 : 15,
    autoSave: false,
    reopenPreviousWorkspaceOnStartup: false,
    confirmCloseWithUnsavedChanges: false,
  );
  final boundaryKey = GlobalKey();
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(workspacePath),
        initialSystemAccentColorProvider.overrideWithValue(
          busyMarkDefaultAccentColor,
        ),
        gitRepositoryGatewayProvider.overrideWithValue(const GitCliGateway()),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore(settings.toJson()),
        ),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        richClipboardServiceProvider.overrideWithValue(
          _RuntimeExternalClipboardService(),
        ),
        localHistoryStoreProvider.overrideWithValue(
          FileLocalHistoryStore(
            rootDirectory: () async => Directory(p.join(output.path, 'store')),
          ),
        ),
        localHistoryTimerFactoryProvider.overrideWithValue(
          (_, callback) => Timer(const Duration(milliseconds: 450), callback),
        ),
      ],
      child: _HistoryVisualHarness(
        mode: mode,
        primaryPath: primaryPath,
        deletePath: deletePath,
        output: output,
        boundaryKey: boundaryKey,
      ),
    ),
  );
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1280, 800), center: true),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

class _HistoryVisualHarness extends ConsumerStatefulWidget {
  const _HistoryVisualHarness({
    required this.mode,
    required this.primaryPath,
    required this.deletePath,
    required this.output,
    required this.boundaryKey,
  });

  final String mode;
  final String primaryPath;
  final String? deletePath;
  final Directory output;
  final GlobalKey boundaryKey;

  @override
  ConsumerState<_HistoryVisualHarness> createState() =>
      _HistoryVisualHarnessState();
}

class _HistoryVisualHarnessState extends ConsumerState<_HistoryVisualHarness> {
  final _screenshots = <String>[];
  final _checks = <String, bool>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: widget.boundaryKey, child: const BusyMarkApp());

  Future<void> _run() async {
    try {
      final workspace = ref.read(workspaceControllerProvider.notifier);
      final localHistory = ref.read(localHistoryControllerProvider.notifier);
      await _waitFor(
        () => ref.read(workspaceControllerProvider).workspace != null,
        'workspace open',
      );
      if (ref.read(workspaceControllerProvider).activeBuffer?.filePath !=
          widget.primaryPath) {
        _check(
          await workspace.openActiveFile(widget.primaryPath),
          'primary document open',
        );
      }
      await _waitFor(
        () => ref.read(workspaceControllerProvider).activeBuffer != null,
        'active document',
      );
      await _waitFor(
        () => _hasWidgetNamed('_Sidebar'),
        'workspace sidebar listeners',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      await _seedClipboard();
      _check(
        await ref
            .read(busyMarkCommandRegistryProvider)
            .execute(BusyMarkCommandIds.clipboardHistory),
        'Clipboard History command',
      );
      await _waitFor(
        _hasWidget<ClipboardHistoryPanel>,
        'Clipboard History view',
      );
      await _capture('${widget.mode}-clipboard-history-1280x800.png');
      await _exerciseCurrentClipboard();

      var buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      await localHistory.observeOpened(buffer);
      final baseline = buffer.text;
      final saved = _savedVersion(baseline);
      workspace.updateActiveText(saved, sourceFilePath: buffer.filePath);
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      _check(
        await localHistory.captureSaved(
          LocalHistoryBufferSnapshot.fromBuffer(buffer),
        ),
        'saved event captured',
      );
      _check(
        await workspace.saveActive(overwriteExternalChanges: true),
        'explicit save captured',
      );
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      workspace.updateActiveText(
        _checkpointVersion(buffer.text),
        sourceFilePath: buffer.filePath,
      );
      await Future<void>.delayed(const Duration(milliseconds: 850));
      await localHistory.refresh();
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      workspace.updateActiveText(
        _currentVersion(buffer.text),
        sourceFilePath: buffer.filePath,
      );
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      await localHistory.selectDocumentForBuffer(buffer);
      await localHistory.refresh();
      _check(
        await ref
            .read(busyMarkCommandRegistryProvider)
            .execute(BusyMarkCommandIds.localHistory),
        'Local History command',
      );
      await _waitFor(_hasWidget<LocalHistoryPanel>, 'Local History view');
      await _waitFor(
        () =>
            !ref.read(localHistoryControllerProvider).loading &&
            ref
                .read(localHistoryControllerProvider)
                .selectedRevisions
                .isNotEmpty,
        'Local History revisions',
      );
      await _capture('${widget.mode}-local-history-1280x800.png');

      final historyState = ref.read(localHistoryControllerProvider);
      final historyDocument = historyState.selectedDocument!;
      final revisionSummary = historyState.selectedRevisions.lastWhere(
        (revision) => revision.reason == LocalHistoryCaptureReason.baseline,
        orElse: () => historyState.selectedRevisions.last,
      );
      await localHistory.selectRevision(revisionSummary.id);
      await _waitFor(
        () => ref.read(localHistoryControllerProvider).selectedRevision != null,
        'selected revision',
      );
      await windowManager.setSize(const Size(1920, 1080));
      await _capture('${widget.mode}-comparison-1920x1080.png');

      final selectedRevision = ref
          .read(localHistoryControllerProvider)
          .selectedRevision!;
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      final comparison = compareSource(
        SourceComparisonInput(
          id: selectedRevision.summary.id,
          version: selectedRevision.summary.capturedAt.microsecondsSinceEpoch,
          label: 'Selected revision',
          source: selectedRevision.source,
        ),
        SourceComparisonInput(
          id: buffer.id,
          version: buffer.revision,
          label: 'Current editor content',
          source: buffer.text,
        ),
      );
      final exactChange = comparison.changes.where((change) => change.exact);
      _check(exactChange.isNotEmpty, 'exact comparison region available');
      _check(
        await workspace.restoreLocalHistoryRevision(
          document: historyDocument,
          revision: selectedRevision,
          comparison: comparison,
          change: exactChange.first,
        ),
        'fragment restore',
      );
      await localHistory.refresh();
      await _capture('${widget.mode}-fragment-restored-1920x1080.png');

      if (widget.deletePath case final deletePath?) {
        await _verifyDeletedRecovery(workspace, localHistory, deletePath);
      }

      _checks['clipboardEntries'] =
          ref.read(clipboardHistoryControllerProvider).entries.length >= 4;
      _checks['revisionReasons'] = ref
          .read(localHistoryControllerProvider)
          .snapshot
          .revisions
          .map((revision) => revision.reason)
          .toSet()
          .containsAll({
            LocalHistoryCaptureReason.baseline,
            LocalHistoryCaptureReason.saved,
            LocalHistoryCaptureReason.automaticCheckpoint,
            LocalHistoryCaptureReason.beforeRestore,
          });
      final passed = _checks.values.every((value) => value);
      await File(
        p.join(widget.output.path, '${widget.mode}-report.json'),
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'passed': passed,
          'checks': _checks,
          'screenshots': _screenshots,
        }),
      );
      if (!passed) exitCode = 1;
      await workspace.discardRecoveryForShutdown();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await SystemNavigator.pop();
    } catch (error, stackTrace) {
      await File(
        p.join(widget.output.path, '${widget.mode}-error.txt'),
      ).writeAsString('$error\n$stackTrace');
      exit(1);
    }
  }

  Future<void> _seedClipboard() async {
    final workspaceState = ref.read(workspaceControllerProvider);
    final buffer = workspaceState.activeBuffer!;
    final origin = BusyMarkClipboardOrigin(
      documentId: buffer.id,
      documentName: buffer.displayName,
      documentPath: buffer.filePath,
    );
    final controller = ref.read(clipboardHistoryControllerProvider.notifier);
    const externalText =
        'Safe deployment\n\nUse staged rollout with a rollback plan.\n\n'
        'Verify health\nKeep the prior package';
    const externalHtml =
        '<h2>Safe deployment</h2>'
        '<p>Use <strong>staged rollout</strong> with a '
        '<a href="https://example.test/rollback">rollback plan</a>.</p>'
        '<ul><li>Verify health</li><li>Keep the prior package</li></ul>';
    final nativeWrite = await ref
        .read(richClipboardServiceProvider)
        .write(const RichClipboardData(text: externalText, html: externalHtml));
    _check(nativeWrite, 'native clipboard publication');
    await controller.refreshCurrentClipboard();
    final current = ref
        .read(clipboardHistoryControllerProvider)
        .currentClipboard;
    _check(
      current?.html == externalHtml && current?.text == externalText,
      'current external HTML retained before paste',
    );
    const sourceSelection =
        '## Safe deployment\n\nUse **staged rollout** with a rollback plan.';
    controller.retain(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.richText,
        text: 'Safe deployment\n\nUse staged rollout with a rollback plan.',
        sourceText: sourceSelection,
        html:
            '<h2>Safe deployment</h2><p>Use <strong>staged rollout</strong> with a rollback plan.</p>',
        origin: origin,
      ),
    );
    controller.retain(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.text,
        text:
            'curl --fail-with-body https://status.example.test/health\n'
            'printf "deployment ready\\n"',
        sourceText:
            '```bash\n'
            'curl --fail-with-body https://status.example.test/health\n'
            'printf "deployment ready\\n"\n'
            '```',
        origin: origin,
      ),
    );
    controller.retain(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.text,
        text:
            '| Environment | Owner | Status |\n'
            '| --- | --- | --- |\n'
            '| Preview | Docs | Ready |',
        sourceText:
            '| Environment | Owner | Status |\n'
            '| --- | --- | --- |\n'
            '| Preview | Docs | Ready |',
        origin: origin,
      ),
    );
    controller.retain(
      BusyMarkClipboardCapture(
        kind: BusyMarkClipboardContentKind.text,
        text:
            '<procedure title="Rotate credentials">\n'
            '  <step>Publish the new secret.</step>\n'
            '</procedure>',
        sourceText:
            '<procedure title="Rotate credentials">\n'
            '  <step>Publish the new secret.</step>\n'
            '</procedure>',
        origin: origin,
      ),
    );
    final imageFile = File(
      p.join(p.dirname(widget.primaryPath), '..', 'images', 'logo.png'),
    );
    if (await imageFile.exists()) {
      controller.retain(
        BusyMarkClipboardCapture(
          kind: BusyMarkClipboardContentKind.image,
          imageBytes: Uint8List.fromList(await imageFile.readAsBytes()),
          imageMimeType: 'image/png',
          imageDisplayName: 'deployment-overview.png',
          imageWidth: 320,
          imageHeight: 180,
          origin: origin,
        ),
      );
    }
  }

  Future<void> _exerciseCurrentClipboard() async {
    const externalHtml =
        '<h2>Safe deployment</h2>'
        '<p>Use <strong>staged rollout</strong> with a '
        '<a href="https://example.test/rollback">rollback plan</a>.</p>'
        '<ul><li>Verify health</li><li>Keep the prior package</li></ul>';
    final controller = ref.read(clipboardHistoryControllerProvider.notifier);
    final current = ref
        .read(clipboardHistoryControllerProvider)
        .currentClipboard!;
    await _waitFor(
      () => ref.read(clipboardInsertionRegistryProvider).target != null,
      'clipboard insertion target',
    );
    final firstInsertion = await ref
        .read(clipboardInsertionRegistryProvider)
        .paste(current, plainText: false);
    _check(
      firstInsertion == ClipboardPasteResult.inserted,
      'current external HTML inserted',
    );
    controller.retainCurrentAfterPaste(current);
    await Clipboard.setData(const ClipboardData(text: 'Clipboard replaced'));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await WidgetsBinding.instance.endOfFrame;
    await _waitFor(
      () => ref.read(clipboardInsertionRegistryProvider).target != null,
      'clipboard insertion target after first paste',
    );
    final retained = ref
        .read(clipboardHistoryControllerProvider)
        .entries
        .firstWhere((entry) => entry.html == externalHtml);
    final secondInsertion = await ref
        .read(clipboardInsertionRegistryProvider)
        .paste(retained, plainText: false);
    _check(
      secondInsertion == ClipboardPasteResult.inserted,
      'retained external HTML reused after clipboard replacement',
    );
    final insertedSource = ref
        .read(workspaceControllerProvider)
        .activeBuffer!
        .text;
    _check(
      RegExp(
            r'^## Safe deployment$',
            multiLine: true,
          ).allMatches(insertedSource).length >=
          2,
      'external HTML heading structure preserved',
    );
    _check(
      insertedSource.contains('**staged rollout**') &&
          insertedSource.contains(
            '[rollback plan](https://example.test/rollback)',
          ) &&
          insertedSource.contains('- Verify health'),
      'external HTML inline and list structure preserved',
    );
  }

  Future<void> _verifyDeletedRecovery(
    WorkspaceController workspace,
    LocalHistoryController localHistory,
    String deletePath,
  ) async {
    _check(await workspace.openActiveFile(deletePath), 'recovery file open');
    final buffer = ref.read(workspaceControllerProvider).activeBuffer!;
    await localHistory.observeOpened(buffer);
    _check(
      await workspace.deleteWorkspaceEntity(deletePath),
      'document delete',
    );
    await localHistory.refresh();
    ref.read(localHistoryOpenRequestProvider.notifier).request();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final deletedDocument = ref
        .read(localHistoryControllerProvider)
        .snapshot
        .documents
        .firstWhere(
          (document) =>
              document.deleted &&
              document.historicalPaths.any(
                (path) => p.equals(path, deletePath),
              ),
        );
    localHistory.selectDocument(deletedDocument.id);
    final revisionSummary = ref
        .read(localHistoryControllerProvider)
        .selectedRevisions
        .first;
    await localHistory.selectRevision(revisionSummary.id);
    await _capture('${widget.mode}-deleted-comparison-1920x1080.png');
    final revision = ref.read(localHistoryControllerProvider).selectedRevision!;
    _check(
      await workspace.restoreMissingLocalHistoryRevision(
        document: deletedDocument,
        revision: revision,
        destinationPath: deletePath,
        overwriteExisting: false,
      ),
      'deleted document recovery',
    );
    await localHistory.refresh();
    await _capture('${widget.mode}-deleted-recovered-1920x1080.png');
    _checks['deletedFileRecovered'] = await File(deletePath).exists();
  }

  String _savedVersion(String source) => source.replaceFirst(
    'The rollout starts in preview.',
    'The rollout starts in preview and requires two reviewers.',
  );

  String _checkpointVersion(String source) => source.replaceFirst(
    '| Preview | Documentation | Ready |',
    '| Preview | Documentation | Monitoring |',
  );

  String _currentVersion(String source) => source
      .replaceFirst('# Deployment handbook', '# Production deployment handbook')
      .replaceFirst(
        'Rollback restores the previous package.',
        'Rollback restores the previous signed package and validates health.',
      );

  Future<void> _capture(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    await WidgetsBinding.instance.endOfFrame;
    final boundary = widget.boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Screenshot boundary is unavailable.');
    }
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) throw StateError('PNG encoding failed.');
    final path = p.join(widget.output.path, name);
    await File(path).writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    _screenshots.add(path);
  }

  bool _hasWidget<T extends Widget>() {
    var found = false;
    void visit(Element element) {
      if (found) return;
      if (element.widget is T) {
        found = true;
        return;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return found;
  }

  bool _hasWidgetNamed(String typeName) {
    var found = false;
    void visit(Element element) {
      if (found) return;
      if (element.widget.runtimeType.toString() == typeName) {
        found = true;
        return;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return found;
  }

  Future<void> _waitFor(bool Function() condition, String description) async {
    for (var attempt = 0; attempt < 240; attempt++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException('Timed out waiting for $description.');
  }

  void _check(bool condition, String description) {
    _checks[description] = condition;
    if (!condition) throw StateError('$description failed.');
  }
}

class _MemorySettingsStore implements LocalSettingsStore {
  _MemorySettingsStore(this.value);

  Map<String, Object?> value;

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}

class _RuntimeExternalClipboardService extends RichClipboardService {
  final RichClipboardService _native = RichClipboardService();
  RichClipboardData? _externalRead;

  @override
  Future<bool> write(RichClipboardData data) async {
    final written = await _native.write(data);
    if (written) {
      _externalRead = RichClipboardData(text: data.text, html: data.html);
    }
    return written;
  }

  @override
  Future<RichClipboardData> read() async {
    final external = _externalRead;
    return external ?? await _native.read();
  }
}
