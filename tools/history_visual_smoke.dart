// Builds a disposable native UI verification target for Clipboard History and
// Local History. The target drives the production controllers and widgets; it
// does not replace them with screenshot-only fixtures.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/command_registry.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/clipboard/clipboard_history_controller.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
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
import 'package:busymark/src/workspace/document_buffer.dart';
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
  final realPolicyTimer =
      Platform.environment['BUSYMARK_HISTORY_REAL_POLICY'] == '1';
  final repairMode = Platform.environment['BUSYMARK_HISTORY_REPAIR'] == '1';
  final historyRoot = Directory(p.join(output.path, 'store'));
  await historyRoot.create(recursive: true);
  var contentions = 0;
  final historyStore = repairMode
      // This disposable desktop verification target uses the internal seam.
      // ignore: invalid_use_of_visible_for_testing_member
      ? FileLocalHistoryStore.testing(
          rootDirectory: () async => historyRoot,
          lockBudget: const Duration(milliseconds: 400),
          acquireLock: (handle) async {
            try {
              await handle.lock(FileLock.exclusive);
            } on FileSystemException {
              contentions++;
              rethrow;
            }
          },
        )
      : FileLocalHistoryStore(rootDirectory: () async => historyRoot);
  final holder = repairMode
      ? await _DesktopLockHolder.start(historyRoot)
      : null;
  final sessions = MemoryDocumentSessionStore();
  if (repairMode) {
    sessions.value = WorkspaceSessionSnapshot(
      workspacePath: workspacePath,
      tabs: [
        DocumentSessionEntry(
          id: 'restored-desktop',
          filePath: primaryPath,
          untitledName: null,
          editorState: const DocumentEditorState(),
        ),
      ],
      activeBufferId: 'restored-desktop',
    );
  }

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
    reopenPreviousWorkspaceOnStartup: repairMode,
    confirmCloseWithUnsavedChanges: false,
  );
  final boundaryKey = GlobalKey();
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(
          repairMode ? null : workspacePath,
        ),
        initialSystemAccentColorProvider.overrideWithValue(
          busyMarkDefaultAccentColor,
        ),
        gitRepositoryGatewayProvider.overrideWithValue(const GitCliGateway()),
        localSettingsStoreProvider.overrideWithValue(
          _MemorySettingsStore(settings.toJson()),
        ),
        documentSessionStoreProvider.overrideWithValue(sessions),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        richClipboardServiceProvider.overrideWithValue(
          _RuntimeExternalClipboardService(),
        ),
        localHistoryStoreProvider.overrideWithValue(historyStore),
        if (!realPolicyTimer && !repairMode)
          localHistoryTimerFactoryProvider.overrideWithValue(
            (_, callback) => Timer(const Duration(seconds: 2), callback),
          ),
      ],
      child: _HistoryVisualHarness(
        mode: mode,
        primaryPath: primaryPath,
        deletePath: deletePath,
        output: output,
        boundaryKey: boundaryKey,
        realPolicyTimer: realPolicyTimer,
        initialHolder: holder,
        contentions: () => contentions,
        repairStore: historyStore,
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
    required this.realPolicyTimer,
    this.initialHolder,
    this.contentions,
    this.repairStore,
  });

  final String mode;
  final String primaryPath;
  final String? deletePath;
  final Directory output;
  final GlobalKey boundaryKey;
  final bool realPolicyTimer;
  final _DesktopLockHolder? initialHolder;
  final int Function()? contentions;
  final FileLocalHistoryStore? repairStore;

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

      if (widget.initialHolder != null) {
        await _runRepair();
        return;
      }

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
      await _waitForEditorSourceToSettle();

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
        'Local History baseline',
      );
      var buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      final baseline = buffer.text;
      final saved = _savedVersion(baseline);
      workspace.updateActiveText(saved, sourceFilePath: buffer.filePath);
      _check(
        await workspace.saveActive(overwriteExternalChanges: true),
        'explicit save captured',
      );
      await _waitForRevisionSource(saved, null, 'saved source publication');
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      final checkpoint = _checkpointVersion(buffer.text);
      workspace.updateActiveText(checkpoint, sourceFilePath: buffer.filePath);
      await _waitForRevisionSource(
        checkpoint,
        LocalHistoryCaptureReason.automaticCheckpoint,
        'automatic checkpoint publication',
      );
      await _capture('${widget.mode}-local-history-1280x800.png');

      await localHistory.search('Monitoring');
      buffer = ref.read(workspaceControllerProvider).activeBuffer!;
      final current = _currentVersion(buffer.text);
      workspace.updateActiveText(current, sourceFilePath: buffer.filePath);
      if (widget.realPolicyTimer) {
        _check(
          await workspace.saveActive(overwriteExternalChanges: true),
          'filtered explicit save captured',
        );
        await _waitForRevisionSource(
          current,
          null,
          'filtered saved-source publication',
        );
      } else {
        await _waitForRevisionSource(
          current,
          LocalHistoryCaptureReason.automaticCheckpoint,
          'filtered checkpoint publication',
        );
      }
      await _waitFor(
        () =>
            !ref.read(localHistoryControllerProvider).searching &&
            ref.read(localHistoryControllerProvider).searchQuery ==
                'Monitoring' &&
            ref.read(localHistoryControllerProvider).searchMatches.length >= 2,
        'live filtered Local History rows',
      );
      await _capture('${widget.mode}-local-history-filtered-1280x800.png');
      await localHistory.search('');

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
      await _capture('${widget.mode}-fragment-restored-1920x1080.png');

      if (widget.deletePath case final deletePath?) {
        await _verifyDeletedRecovery(workspace, localHistory, deletePath);
      }

      _checks['clipboardEntries'] =
          ref.read(clipboardHistoryControllerProvider).entries.length >= 4;
      _checks['defaultCheckpointPolicy'] =
          ref
              .read(localHistoryControllerProvider.notifier)
              .policy
              .checkpointInterval ==
          const Duration(seconds: 60);
      _checks['revisionReasons'] = ref
          .read(localHistoryControllerProvider)
          .snapshot
          .revisions
          .map((revision) => revision.reason)
          .toSet()
          .containsAll({
            LocalHistoryCaptureReason.baseline,
            LocalHistoryCaptureReason.automaticCheckpoint,
            LocalHistoryCaptureReason.beforeRestore,
          });
      final passed = _checks.values.every((value) => value);
      await File(
        p.join(widget.output.path, '${widget.mode}-report.json'),
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'passed': passed,
          'timerMode': widget.realPolicyTimer
              ? 'production-default'
              : 'visual-smoke-2s',
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

  Future<void> _runRepair() async {
    final workspace = ref.read(workspaceControllerProvider.notifier);
    final history = ref.read(localHistoryControllerProvider.notifier);
    final store = widget.repairStore!;
    final root = Directory(p.join(widget.output.path, 'store'));
    _DesktopLockHolder? holder = widget.initialHolder;
    bool draftStillPresent(DocumentBuffer expected) {
      final current = ref.read(workspaceControllerProvider).activeBuffer;
      return current?.id == expected.id &&
          current?.revision == expected.revision &&
          current?.text == expected.text &&
          current?.isDirty == expected.isDirty;
    }

    try {
      final original = ref.read(workspaceControllerProvider).activeBuffer!;
      await _waitFor(
        () =>
            history.warningForBuffer(original.id)?.kind ==
            LocalHistoryWarningKind.capture,
        'restored capture failure',
      );
      _check(
        widget.contentions!() > 0,
        'startup encountered actual cross-process contention',
      );
      await holder!.release();
      holder = null;
      await history.refresh();
      _check(
        history.warningForBuffer(original.id)?.kind ==
            LocalHistoryWarningKind.capture,
        'refresh does not erase unresolved baseline',
      );

      holder = await _DesktopLockHolder.start(root);
      await ref
          .read(busyMarkCommandRegistryProvider)
          .execute(BusyMarkCommandIds.back);
      await _waitFor(
        () =>
            ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/',
        'Back to welcome',
      );
      await _activateLabel('Create Markdown File');
      await _waitFor(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.id !=
                original.id &&
            ref
                    .read(appRouterProvider)
                    .routeInformationProvider
                    .value
                    .uri
                    .path ==
                '/workspace',
        'first new draft',
      );
      var draft = ref.read(workspaceControllerProvider).activeBuffer!;
      _check(
        history.warningForBuffer(draft.id) == null,
        'old failure does not become the new editor banner',
      );
      _check(
        ref.read(localHistoryControllerProvider).warning?.ownerBufferId ==
            original.id,
        'retained failure identifies its closed owner',
      );
      await _capture('repair-new-draft.png');

      await ref
          .read(busyMarkCommandRegistryProvider)
          .execute(BusyMarkCommandIds.back);
      await _activateLabel('Discard');
      await _waitFor(
        () =>
            ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            '/',
        'Back after pristine discard',
      );
      await _activateLabel('Create Markdown File');
      await _waitFor(
        () =>
            ref.read(workspaceControllerProvider).activeBuffer?.id !=
                draft.id &&
            ref
                    .read(appRouterProvider)
                    .routeInformationProvider
                    .value
                    .uri
                    .path ==
                '/workspace',
        'second new draft',
      );
      draft = ref.read(workspaceControllerProvider).activeBuffer!;
      _check(
        draft.text.isEmpty && history.warningForBuffer(draft.id) == null,
        'reported sequence ends with a clean new editor',
      );
      await holder.release();
      holder = null;
      _check(
        await history.flushAll(
          ref.read(workspaceControllerProvider).documentBuffers,
        ),
        'closed baseline recovers and settles',
      );
      var snapshot = await store.load();
      _check(
        snapshot.revisions.length == 1,
        'pristine discard made no protective write',
      );
      _check(
        (await store.readRevision(snapshot.revisions.single.id))!.source ==
            original.text,
        'original restored source retained exactly',
      );

      workspace.updateActiveText('Transiently protected desktop draft');
      draft = ref.read(workspaceControllerProvider).activeBuffer!;
      holder = await _DesktopLockHolder.start(root);
      final before = widget.contentions!();
      var finished = false;
      final protecting = history
          .captureBeforeLoss(
            LocalHistoryBufferSnapshot.fromBuffer(draft),
            LocalHistoryCaptureReason.beforeDiscard,
          )
          .then((result) {
            finished = true;
            return result;
          });
      await _waitFor(
        () => widget.contentions!() > before,
        'protective acquisition contention',
      );
      _check(
        !finished,
        'protective work remains pending during transient contention',
      );
      await holder.release();
      holder = null;
      _check(
        await protecting,
        'transient contention recovers without capture failure',
      );
      _check(
        history.warningForBuffer(draft.id) == null,
        'transient recovery has no stale warning',
      );

      workspace.updateActiveText('Keep this nonempty desktop draft');
      draft = ref.read(workspaceControllerProvider).activeBuffer!;
      holder = await _DesktopLockHolder.start(root);
      _check(
        !await workspace.closeDocumentBuffer(draft.id, discard: true),
        'failed protection rejects nonempty discard',
      );
      _check(
        draftStillPresent(draft),
        'failed discard retains exact buffer and contents',
      );
      await _capture('repair-failed-nonempty-discard.png');
      await holder.release();
      holder = null;
      _check(
        await history.flushAll(
          ref.read(workspaceControllerProvider).documentBuffers,
        ),
        'failed protective work recovers',
      );
      _check(
        draftStillPresent(draft),
        'background recovery does not execute the rejected discard',
      );
      snapshot = await store.load();
      final sources = <String>[];
      for (final revision in snapshot.revisions) {
        sources.add((await store.readRevision(revision.id))!.source);
      }
      _check(
        sources.contains(original.text) &&
            sources.contains('Transiently protected desktop draft') &&
            sources.contains(draft.text),
        'all retained revision contents verified',
      );
      await File(
        p.join(widget.output.path, 'repair-report.json'),
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'passed': _checks.values.every((value) => value),
          'checks': _checks,
          'revisionSources': sources,
          'screenshots': _screenshots,
          'contentions': widget.contentions!(),
        }),
      );
      await SystemNavigator.pop();
    } finally {
      await holder?.release();
    }
  }

  Future<void> _activateLabel(String label) async {
    VoidCallback? callback;
    await _waitFor(() {
      void visit(Element element) {
        if (element.widget case Text(:final data) when data == label) {
          element.visitAncestorElements((ancestor) {
            final widget = ancestor.widget;
            if (widget is ButtonStyleButton && widget.onPressed != null) {
              callback = widget.onPressed;
              return false;
            }
            if (widget is InkWell && widget.onTap != null) {
              callback = widget.onTap;
              return false;
            }
            return true;
          });
        }
        element.visitChildren(visit);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(visit);
      return callback != null;
    }, 'visible $label action');
    callback!();
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
    final current = ref
        .read(clipboardHistoryControllerProvider)
        .currentClipboard!;
    await _waitFor(
      () => ref.read(clipboardInsertionRegistryProvider).target != null,
      'clipboard insertion target',
    );
    final firstInsertion = await ref
        .read(clipboardInsertionRegistryProvider)
        .paste(current, mode: BusyMarkPasteMode.normal);
    _check(
      firstInsertion == ClipboardPasteResult.inserted,
      'current external HTML inserted',
    );
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
        .paste(retained, mode: BusyMarkPasteMode.normal);
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
    _check(
      await workspace.deleteWorkspaceEntity(deletePath),
      'document delete',
    );
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

  Future<void> _waitForRevisionSource(
    String source,
    LocalHistoryCaptureReason? reason,
    String description,
  ) async {
    final store = ref.read(localHistoryStoreProvider);
    final maximumAttempts = widget.realPolicyTimer ? 900 : 240;
    for (var attempt = 0; attempt < maximumAttempts; attempt++) {
      final summaries = ref
          .read(localHistoryControllerProvider)
          .selectedRevisions
          .where((revision) => reason == null || revision.reason == reason);
      for (final summary in summaries) {
        final revision = await store.readRevision(summary.id);
        if (revision?.source == source) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException('Timed out waiting for $description.');
  }

  Future<void> _waitForEditorSourceToSettle() async {
    var stableChecks = 0;
    var revision = ref.read(workspaceControllerProvider).activeBuffer!.revision;
    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final currentRevision = ref
          .read(workspaceControllerProvider)
          .activeBuffer!
          .revision;
      if (currentRevision == revision) {
        stableChecks += 1;
        if (stableChecks == 10) return;
      } else {
        revision = currentRevision;
        stableChecks = 0;
      }
    }
    throw TimeoutException('Timed out waiting for editor source to settle.');
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

class _DesktopLockHolder {
  _DesktopLockHolder(this.process, this.errors);
  final Process process;
  final Future<String> errors;
  bool released = false;

  static Future<_DesktopLockHolder> start(Directory root) async {
    final process = await Process.start('/usr/bin/python3', [
      '-c',
      'import fcntl,sys,select\nf=open(sys.argv[1],"a+b")\nfcntl.lockf(f,fcntl.LOCK_EX|fcntl.LOCK_NB)\nprint("locked",flush=True)\nselect.select([sys.stdin],[],[],30)\nf.close()',
      p.join(root.path, '.store.lock'),
    ]);
    final errors = process.stderr.transform(utf8.decoder).join();
    try {
      final ready = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 5));
      if (ready != 'locked') throw StateError('Desktop lock holder failed');
      return _DesktopLockHolder(process, errors);
    } on Object {
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 5));
      rethrow;
    }
  }

  Future<void> release() async {
    if (released) return;
    released = true;
    int code;
    try {
      process.stdin.writeln('release');
      await process.stdin.close();
      code = await process.exitCode.timeout(const Duration(seconds: 5));
    } on Object {
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 5));
      rethrow;
    }
    if (code != 0) throw StateError('Desktop holder: ${await errors}');
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
