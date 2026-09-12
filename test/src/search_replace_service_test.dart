import 'dart:async';
import 'dart:io';

import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/search/search_replace_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const replacementService = SearchReplacementService();

  test('Unicode regex replacement preserves complete characters', () async {
    const options = SourceSearchOptions(query: '.', regex: true);
    final worker = SearchReplacementWorker();
    addTearDown(worker.dispose);
    final all = await worker.previewText(
      source: '😀😀',
      options: options,
      replacement: 'X',
    );
    expect(all!.apply(), 'XX');
    final current = await worker.previewText(
      source: '😀😀',
      options: options,
      replacement: 'X',
      targetStart: 0,
      targetEnd: 2,
    );
    expect(current!.apply(), 'X😀');
    for (final range in [(0, 1), (1, 2), (1, 3)]) {
      final unsafe = replacementService.previewMatch(
        source: '😀😀',
        options: options,
        replacement: 'X',
        start: range.$1,
        end: range.$2,
      );
      expect(unsafe.matches, isEmpty);
      expect(unsafe.apply(), '😀😀');
    }
  });

  test('zero-length replacement limitation survives worker transfer', () async {
    final worker = SearchReplacementWorker();
    addTearDown(worker.dispose);
    final preview = await worker.previewText(
      source: 'cat',
      options: const SourceSearchOptions(query: '^', regex: true),
      replacement: 'X',
    );
    expect(preview!.hasZeroLengthMatches, isTrue);
    expect(preview.apply(), 'cat');
  });

  for (final count in [4999, 5000, 5001]) {
    test('workspace replacement limit at $count actual matches', () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-search-limit-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File(p.join(directory.path, 'a.md'));
      final tail = File(p.join(directory.path, 'b.md'));
      await file.writeAsString('cat ' * (count > 5000 ? 5000 : count));
      await tail.writeAsString(count > 5000 ? 'cat' : 'nothing');
      final state = WorkspaceState(
        workspace: Workspace(
          id: directory.path,
          rootPath: directory.path,
          kind: WorkspaceKind.markdownFolder,
          openedAt: DateTime(2026),
          files: [
            await _documentFile(file, directory.path),
            await _documentFile(tail, directory.path),
          ],
          diagnostics: const [],
        ),
      );
      final preview = await replacementService.previewWorkspace(
        state: state,
        workspaceService: const WorkspaceService(),
        options: const SourceSearchOptions(query: 'cat'),
        replacement: 'dog',
      );
      expect(preview.matchCount, count > 5000 ? 5000 : count);
      expect(preview.isComplete, count <= 5000);
    });
  }

  test('workspace replacement cancels a running expensive regex', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-search-cancel-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'a.md'));
    await file.writeAsString('${'a' * 100}b');
    final state = WorkspaceState(
      workspace: Workspace(
        id: directory.path,
        rootPath: directory.path,
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime(2026),
        files: [await _documentFile(file, directory.path)],
        diagnostics: const [],
      ),
    );
    final cancellation = WorkspaceReplacementCancellation();
    addTearDown(cancellation.cancel);
    final pending = replacementService.previewWorkspace(
      state: state,
      workspaceService: const WorkspaceService(),
      options: const SourceSearchOptions(query: r'^(a+)+$', regex: true),
      replacement: 'X',
      cancellation: cancellation,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    cancellation.cancel();
    final preview = await pending.timeout(const Duration(seconds: 5));
    expect(preview.isComplete, isFalse);
    expect(preview.issues.single.kind, WorkspaceReplacementIssueKind.cancelled);
  });

  test(
    'workspace scope includes closed Writerside documents and ignores unrelated open files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-search-scope-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final config = File(p.join(directory.path, 'writerside.cfg'));
      final image = File(p.join(directory.path, 'image.png'));
      final unknown = File(p.join(directory.path, 'unknown.bin'));
      for (final file in [config, image, unknown]) {
        await file.writeAsString('cat');
      }
      final openLoad = await const WorkspaceService().loadTextWithSnapshot(
        unknown.path,
      );
      final buffer = DocumentBuffer.file(
        id: 'unknown',
        filePath: unknown.path,
        text: openLoad.text,
        snapshot: openLoad.snapshot,
        format: openLoad.format,
      );
      final state = WorkspaceState(
        workspace: Workspace(
          id: directory.path,
          rootPath: directory.path,
          kind: WorkspaceKind.writersideModule,
          openedAt: DateTime(2026),
          files: [
            for (final entry in [
              (config, DocumentKind.config),
              (image, DocumentKind.image),
              (unknown, DocumentKind.unknown),
            ])
              DocumentFile(
                absolutePath: entry.$1.path,
                relativePath: p.basename(entry.$1.path),
                kind: entry.$2,
                size: 3,
                lastModified: DateTime(2026),
              ),
          ],
          diagnostics: const [],
        ),
        documentBuffers: [buffer],
        activeBufferId: buffer.id,
      );
      final preview = await replacementService.previewWorkspace(
        state: state,
        workspaceService: const WorkspaceService(),
        options: const SourceSearchOptions(query: 'cat'),
        replacement: 'dog',
      );
      expect(preview.files.single.filePath, config.path);
      final result = await replacementService.applyWorkspace(
        preview: preview,
        selectedMatchIds: {preview.files.single.matches.single.id},
        currentState: () => state,
        updateBuffer: (_, _) => fail('Unrelated open buffer must be excluded'),
        workspaceService: const WorkspaceService(),
      );
      expect(result.appliedMatches, 1);
      expect(await config.readAsString(), 'dog');
      expect(await image.readAsString(), 'cat');
      expect(await unknown.readAsString(), 'cat');
    },
  );

  test('previews and applies plain whole-word replacements', () {
    final preview = replacementService.previewText(
      source: 'cat scatter Cat',
      options: const SourceSearchOptions(query: 'cat', wholeWord: true),
      replacement: 'dog',
    );

    expect(preview.matches.map((match) => match.original), ['cat', 'Cat']);
    expect(preview.apply(), 'dog scatter dog');
  });

  test('text replacement previews enforce their match limit', () {
    const limited = SearchReplacementService(maximumMatches: 2);

    final preview = limited.previewText(
      source: 'a a a',
      options: const SourceSearchOptions(query: 'a'),
      replacement: 'x',
    );

    expect(preview.matches, hasLength(2));
    expect(preview.truncated, isTrue);
  });

  test('replacement worker expands one accepted regex match', () async {
    final worker = SearchReplacementWorker();
    addTearDown(worker.dispose);

    final preview = await worker.previewText(
      source: 'Ada Lovelace',
      options: const SourceSearchOptions(query: r'(\w+) (\w+)', regex: true),
      replacement: r'$2, $1',
      targetStart: 0,
      targetEnd: 12,
    );

    expect(preview, isNotNull);
    expect(preview!.matches.single.replacement, 'Lovelace, Ada');
  });

  test('replacement worker cancels stale plans', () async {
    final worker = SearchReplacementWorker();
    addTearDown(worker.dispose);
    final stale = worker.previewText(
      source: List.filled(10000, 'alpha').join(' '),
      options: const SourceSearchOptions(query: 'alpha'),
      replacement: 'stale',
    );
    final current = worker.previewText(
      source: 'current',
      options: const SourceSearchOptions(query: 'current'),
      replacement: 'fresh',
    );

    expect(await stale, isNull);
    expect((await current)!.apply(), 'fresh');
  });

  test('expands numbered and named regex capture groups', () {
    final numbered = replacementService.previewText(
      source: 'Ada Lovelace; Grace Hopper',
      options: const SourceSearchOptions(query: r'(\w+) (\w+)', regex: true),
      replacement: r'$2, $1',
    );
    final named = replacementService.previewText(
      source: 'x=42',
      options: const SourceSearchOptions(
        query: r'(?<name>\w+)=(?<value>\d+)',
        regex: true,
      ),
      replacement: r'${value}:${name}:$$:$&',
    );

    expect(numbered.apply(), 'Lovelace, Ada; Hopper, Grace');
    expect(named.apply(), r'42:x:$:x=42');
  });

  test('applies only selected preview matches', () {
    final preview = replacementService.previewText(
      source: 'one one one',
      options: const SourceSearchOptions(query: 'one'),
      replacement: 'two',
    );

    expect(
      preview.apply(selectedMatchIds: {preview.matches[1].id}),
      'one two one',
    );
  });

  test(
    'workspace preview uses dirty buffers and writes closed files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-replace-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final openFile = File(p.join(directory.path, 'open.md'));
      final closedFile = File(p.join(directory.path, 'closed.md'));
      await openFile.writeAsString('disk cat');
      await closedFile.writeAsString('closed cat');
      const workspaceService = WorkspaceService();
      final openLoad = await workspaceService.loadTextWithSnapshot(
        openFile.path,
      );
      final buffer = DocumentBuffer.file(
        id: 'open',
        filePath: openFile.path,
        text: openLoad.text,
        snapshot: openLoad.snapshot,
        format: openLoad.format,
      ).edited('dirty cat');
      final workspace = Workspace(
        id: directory.path,
        rootPath: directory.path,
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime(2026),
        activeFilePath: openFile.path,
        openFilePaths: [openFile.path],
        files: [
          await _documentFile(openFile, directory.path),
          await _documentFile(closedFile, directory.path),
        ],
        diagnostics: const [],
      );
      var state = WorkspaceState(
        workspace: workspace,
        documentBuffers: [buffer],
        activeBufferId: buffer.id,
      );

      final preview = await replacementService.previewWorkspace(
        state: state,
        workspaceService: workspaceService,
        options: const SourceSearchOptions(query: 'cat'),
        replacement: 'dog',
      );

      expect(preview.files, hasLength(2));
      expect(
        preview.files
            .singleWhere((file) => file.filePath == openFile.path)
            .sourceKind,
        WorkspaceReplacementSourceKind.dirtyBuffer,
      );
      final result = await replacementService.applyWorkspace(
        preview: preview,
        selectedMatchIds: {
          for (final file in preview.files)
            for (final match in file.matches) match.id,
        },
        currentState: () => state,
        updateBuffer: (bufferId, text) {
          state = state.copyWith(
            documentBuffers: [state.documentBuffers.single.edited(text)],
          );
        },
        workspaceService: workspaceService,
      );

      expect(result.appliedFiles, 2);
      expect(state.documentBuffers.single.text, 'dirty dog');
      expect(await openFile.readAsString(), 'disk cat');
      expect(await closedFile.readAsString(), 'closed dog');
    },
  );

  test('workspace apply skips stale dirty buffers', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-replace-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'open.md'));
    await file.writeAsString('cat');
    const workspaceService = WorkspaceService();
    final load = await workspaceService.loadTextWithSnapshot(file.path);
    final buffer = DocumentBuffer.file(
      id: 'open',
      filePath: file.path,
      text: load.text,
      snapshot: load.snapshot,
      format: load.format,
    ).edited('cat dirty');
    final workspace = Workspace(
      id: directory.path,
      rootPath: directory.path,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: file.path,
      openFilePaths: [file.path],
      files: [await _documentFile(file, directory.path)],
      diagnostics: const [],
    );
    var state = WorkspaceState(
      workspace: workspace,
      documentBuffers: [buffer],
      activeBufferId: buffer.id,
    );
    final preview = await replacementService.previewWorkspace(
      state: state,
      workspaceService: workspaceService,
      options: const SourceSearchOptions(query: 'cat'),
      replacement: 'dog',
    );
    state = state.copyWith(
      documentBuffers: [state.documentBuffers.single.edited('changed again')],
    );

    final result = await replacementService.applyWorkspace(
      preview: preview,
      selectedMatchIds: {preview.files.single.matches.single.id},
      currentState: () => state,
      updateBuffer: (_, _) => fail('stale buffer must not be updated'),
      workspaceService: workspaceService,
    );

    expect(result.appliedFiles, 0);
    expect(
      result.issues.single.kind,
      WorkspaceReplacementIssueKind.bufferRevisionChanged,
    );
  });

  test('truncated workspace previews cannot be applied', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-replace-truncated-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('cat cat');
    const workspaceService = WorkspaceService();
    const limitedService = SearchReplacementService(maximumMatches: 1);
    final workspace = Workspace(
      id: directory.path,
      rootPath: directory.path,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      files: [await _documentFile(file, directory.path)],
      diagnostics: const [],
    );
    final state = WorkspaceState(workspace: workspace);
    final preview = await limitedService.previewWorkspace(
      state: state,
      workspaceService: workspaceService,
      options: const SourceSearchOptions(query: 'cat'),
      replacement: 'dog',
    );

    expect(preview.isComplete, isFalse);
    final result = await limitedService.applyWorkspace(
      preview: preview,
      selectedMatchIds: {preview.files.single.matches.single.id},
      currentState: () => state,
      updateBuffer: (_, _) => fail('no buffers should be updated'),
      workspaceService: workspaceService,
    );

    expect(result.appliedFiles, 0);
    expect(result.issues.single.kind, WorkspaceReplacementIssueKind.truncated);
    expect(await file.readAsString(), 'cat cat');
  });

  test('stale later files abort before earlier files are changed', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-replace-preflight-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = File(p.join(directory.path, 'a.md'));
    final second = File(p.join(directory.path, 'b.md'));
    await first.writeAsString('cat first');
    await second.writeAsString('cat second');
    const workspaceService = WorkspaceService();
    final workspace = Workspace(
      id: directory.path,
      rootPath: directory.path,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      files: [
        await _documentFile(first, directory.path),
        await _documentFile(second, directory.path),
      ],
      diagnostics: const [],
    );
    final state = WorkspaceState(workspace: workspace);
    final preview = await replacementService.previewWorkspace(
      state: state,
      workspaceService: workspaceService,
      options: const SourceSearchOptions(query: 'cat'),
      replacement: 'dog',
    );
    await second.writeAsString('changed after preview');

    final result = await replacementService.applyWorkspace(
      preview: preview,
      selectedMatchIds: {
        for (final file in preview.files)
          for (final match in file.matches) match.id,
      },
      currentState: () => state,
      updateBuffer: (_, _) => fail('no buffers should be updated'),
      workspaceService: workspaceService,
    );

    expect(result.appliedFiles, 0);
    expect(
      result.issues.single.kind,
      WorkspaceReplacementIssueKind.changedSincePreview,
    );
    expect(await first.readAsString(), 'cat first');
    expect(await second.readAsString(), 'changed after preview');
  });

  test(
    'rollback preserves a concurrent edit and reports displaced content',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      final directory = await Directory.systemTemp.createTemp(
        'busymark-replace-rollback-conflict-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'a.md'));
      final second = File(p.join(directory.path, 'b.md'));
      await first.writeAsString('cat first');
      await second.writeAsString('cat second');
      var injected = false;
      final workspaceService = WorkspaceService(
        afterBatchFileCommit: (targetPath, committedCount) async {
          if (!injected && committedCount == 1) {
            injected = true;
            await first.writeAsString('external first');
            await second.delete();
          }
        },
      );
      final workspace = Workspace(
        id: directory.path,
        rootPath: directory.path,
        kind: WorkspaceKind.markdownFolder,
        openedAt: DateTime(2026),
        files: [
          await _documentFile(first, directory.path),
          await _documentFile(second, directory.path),
        ],
        diagnostics: const [],
      );
      final state = WorkspaceState(workspace: workspace);
      final preview = await replacementService.previewWorkspace(
        state: state,
        workspaceService: workspaceService,
        options: const SourceSearchOptions(query: 'cat'),
        replacement: 'dog',
      );

      final result = await replacementService.applyWorkspace(
        preview: preview,
        selectedMatchIds: {
          for (final file in preview.files)
            for (final match in file.matches) match.id,
        },
        currentState: () => state,
        updateBuffer: (_, _) => fail('no buffers should be updated'),
        workspaceService: workspaceService,
      );

      expect(result.appliedFiles, 0);
      expect(result.issues, hasLength(1));
      expect(
        result.issues.single.kind,
        WorkspaceReplacementIssueKind.partialApplicationConflict,
      );
      expect(result.issues.single.filePath, first.path);
      expect(await first.readAsString(), 'external first');
      final preservedPath = result.issues.single.preservedPath;
      expect(preservedPath, isNotNull);
      expect(await File(preservedPath!).readAsString(), 'cat first');
    },
  );

  test('workspace apply revalidates open buffers after disk writes', () async {
    if (!Platform.isLinux) {
      return;
    }
    final directory = await Directory.systemTemp.createTemp(
      'busymark-replace-open-race-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final openFile = File(p.join(directory.path, 'open.md'));
    final closedFile = File(p.join(directory.path, 'closed.md'));
    await openFile.writeAsString('open cat');
    await closedFile.writeAsString('closed cat');
    final workspaceService = _PausedBatchWorkspaceService();
    final openLoad = await workspaceService.loadTextWithSnapshot(openFile.path);
    final buffer = DocumentBuffer.file(
      id: 'open',
      filePath: openFile.path,
      text: openLoad.text,
      snapshot: openLoad.snapshot,
      format: openLoad.format,
    ).edited('dirty cat');
    final workspace = Workspace(
      id: directory.path,
      rootPath: directory.path,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: openFile.path,
      openFilePaths: [openFile.path],
      files: [
        await _documentFile(openFile, directory.path),
        await _documentFile(closedFile, directory.path),
      ],
      diagnostics: const [],
    );
    var state = WorkspaceState(
      workspace: workspace,
      documentBuffers: [buffer],
      activeBufferId: buffer.id,
    );
    final preview = await replacementService.previewWorkspace(
      state: state,
      workspaceService: workspaceService,
      options: const SourceSearchOptions(query: 'cat'),
      replacement: 'dog',
    );

    final apply = replacementService.applyWorkspace(
      preview: preview,
      selectedMatchIds: {
        for (final file in preview.files)
          for (final match in file.matches) match.id,
      },
      currentState: () => state,
      updateBuffer: (_, _) => fail('concurrent edit must not be overwritten'),
      workspaceService: workspaceService,
    );
    await workspaceService.batchStarted.future;
    state = state.copyWith(
      documentBuffers: [state.documentBuffers.single.edited('newer edit')],
    );
    workspaceService.releaseBatch();
    final result = await apply;

    expect(result.appliedFiles, 1);
    expect(result.appliedMatches, 1);
    expect(result.issues, hasLength(1));
    expect(
      result.issues.single.kind,
      WorkspaceReplacementIssueKind.bufferRevisionChanged,
    );
    expect(state.documentBuffers.single.text, 'newer edit');
    expect(await closedFile.readAsString(), 'closed dog');
  });
}

class _PausedBatchWorkspaceService extends WorkspaceService {
  final batchStarted = Completer<void>();
  final _release = Completer<void>();

  void releaseBatch() => _release.complete();

  @override
  Future<Map<String, WorkspaceFileSnapshot>> saveFormattedTextBatch(
    List<WorkspaceBatchTextWrite> writes,
  ) async {
    batchStarted.complete();
    await _release.future;
    return super.saveFormattedTextBatch(writes);
  }
}

Future<DocumentFile> _documentFile(File file, String root) async {
  final stat = await file.stat();
  return DocumentFile(
    absolutePath: file.path,
    relativePath: p.relative(file.path, from: root),
    kind: DocumentKind.markdown,
    size: stat.size,
    lastModified: stat.modified,
  );
}
