import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/debug_log.dart';
import '../core/diagnostic.dart';
import '../core/linux_atomic_file_api.dart';
import '../core/path_utils.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_module_service.dart';
import '../writerside/writerside_parsers.dart';
import '../writerside/writerside_document_renderer.dart';
import '../writerside/writerside_document_resolver.dart';
import '../writerside/writerside_instance_service.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_project.dart';
import '../writerside/writerside_toc_editor.dart';
import '../writerside/writerside_topic_creator.dart';
import '../writerside/writerside_topic_file_editor.dart';
import '../writerside/writerside_topic_removal_service.dart';
import 'workspace_model.dart';
import 'text_format_metadata.dart';

class WorkspaceBatchTextWrite {
  const WorkspaceBatchTextWrite({
    required this.path,
    required this.text,
    required this.expectedSnapshot,
    required this.format,
    this.mixedNormalization,
  });

  final String path;
  final String text;
  final WorkspaceFileSnapshot expectedSnapshot;
  final TextFormatMetadata format;
  final LineEndingNormalization? mixedNormalization;
}

class WorkspaceBatchWriteConflict implements Exception {
  const WorkspaceBatchWriteConflict(this.path);

  final String path;
}

class WorkspaceBatchPartialApplicationFile {
  const WorkspaceBatchPartialApplicationFile({
    required this.targetPath,
    required this.preservedPath,
  });

  final String targetPath;
  final String preservedPath;
}

class WorkspaceBatchPartialApplicationConflict implements Exception {
  const WorkspaceBatchPartialApplicationConflict({
    required this.files,
    required this.cause,
  });

  final List<WorkspaceBatchPartialApplicationFile> files;
  final Object cause;
}

class WorkspaceService {
  const WorkspaceService({
    this.markdownParser = const MarkdownParser(),
    this.previewBuilder = const MarkdownPreviewBuilder(),
    WritersideModuleService? writersideService,
    this.writersideProjectCreator = const WritersideProjectCreator(),
    this.writersideInstanceService = const WritersideInstanceService(),
    this.writersideTopicCreator = const WritersideTopicCreator(),
    this.writersideTocEditor = const WritersideTocEditor(),
    this.writersideTopicFileEditor = const WritersideTopicFileEditor(),
    this.writersideTopicRemovalService = const WritersideTopicRemovalService(),
    this.writersideDocumentResolver = const WritersideDocumentResolver(),
    this.writersideDocumentRenderer = const WritersideDocumentRenderer(),
    this.scanOptions = const WorkspaceScanOptions(),
    Future<void> Function(String targetPath)? beforeNewFilePublish,
    Future<void> Function(String targetPath, int committedCount)?
    afterBatchFileCommit,
  }) : writersideService = writersideService ?? const WritersideModuleService(),
       _useWorkspaceScanOptionsForWriterside = writersideService == null,
       _beforeNewFilePublish = beforeNewFilePublish,
       _afterBatchFileCommit = afterBatchFileCommit;

  final MarkdownParser markdownParser;
  final MarkdownPreviewBuilder previewBuilder;
  final WritersideModuleService writersideService;
  final WritersideProjectCreator writersideProjectCreator;
  final WritersideInstanceService writersideInstanceService;
  final WritersideTopicCreator writersideTopicCreator;
  final WritersideTocEditor writersideTocEditor;
  final WritersideTopicFileEditor writersideTopicFileEditor;
  final WritersideTopicRemovalService writersideTopicRemovalService;
  final WritersideDocumentResolver writersideDocumentResolver;
  final WritersideDocumentRenderer writersideDocumentRenderer;
  final WorkspaceScanOptions scanOptions;
  final bool _useWorkspaceScanOptionsForWriterside;
  final Future<void> Function(String targetPath)? _beforeNewFilePublish;
  final Future<void> Function(String targetPath, int committedCount)?
  _afterBatchFileCommit;

  Workspace createUntitledMarkdown({String source = ''}) {
    const fileName = '';
    final now = DateTime.now();
    final markdown = markdownParser.parse(filePath: fileName, source: source);
    return Workspace(
      id: 'untitled:${now.microsecondsSinceEpoch}',
      rootPath: '',
      kind: WorkspaceKind.untitledMarkdown,
      openedAt: now,
      files: const [],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

  Future<Workspace> openPath(String inputPath) async {
    final path = normalizePath(inputPath);
    final fileType = FileSystemEntity.typeSync(path);
    _logOpenPathDiagnostics(inputPath, path, fileType);
    if (fileType == FileSystemEntityType.file) {
      final canonicalPath = p.normalize(
        await File(path).resolveSymbolicLinks(),
      );
      return _openSingleMarkdown(canonicalPath);
    }
    if (fileType != FileSystemEntityType.directory) {
      throw BusyMarkException(
        'workspace.path-does-not-exist',
        args: {'path': path},
      );
    }
    final canonicalPath = p.normalize(
      await Directory(path).resolveSymbolicLinks(),
    );
    if (File(p.join(canonicalPath, 'writerside.cfg')).existsSync() ||
        File(p.join(canonicalPath, 'project.ihp')).existsSync()) {
      return _openWriterside(canonicalPath, preferredModuleRoot: canonicalPath);
    }
    final moduleRoots = await _writersideProjectService.discoverModuleRoots(
      canonicalPath,
    );
    if (moduleRoots.isNotEmpty) {
      return _openWriterside(
        canonicalPath,
        preferredModuleRoot: moduleRoots.first,
      );
    }
    return _openMarkdownFolder(canonicalPath);
  }

  Future<DocumentFile?> resolveWorkspaceDocument(
    Workspace workspace,
    String candidatePath,
  ) async {
    final anchor = await _workspacePathAnchor(workspace);
    final resolution = await _resolveWorkspacePath(
      anchor,
      candidatePath,
      allowRoot: false,
    );
    if (resolution.type != FileSystemEntityType.file) {
      return null;
    }
    final relativePath = p.relative(resolution.path, from: anchor.rootPath);
    if (p
        .split(relativePath)
        .any(versionControlMetadataDirectoryNames.contains)) {
      throw BusyMarkException(
        'workspace.file-operation-outside-root',
        args: {'path': resolution.path},
      );
    }
    return _documentFile(resolution.path, anchor.rootPath);
  }

  Future<Workspace> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) async {
    final result = await writersideProjectCreator.create(request);
    return _openWriterside(
      result.rootPath,
      activeFilePath: result.startTopicPath,
    );
  }

  Future<Workspace> createWritersideTopic(
    Workspace workspace,
    WritersideTopicCreateRequest request, {
    String? instanceTreePath,
  }) async {
    if (workspace.kind != WorkspaceKind.writersideModule ||
        workspace.writersideModule == null) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    final module = await _currentWritersideModule(workspace);
    if (module.instances.isEmpty) {
      throw const BusyMarkException('writerside.topic.instance-tree-missing');
    }
    final instance = _writersideInstanceForTree(module, instanceTreePath);
    var topicsRootDir = module.config.topicsDir;
    if (request.placement != WritersideTopicCreatePlacement.root) {
      final referenceTopic = request.referenceTopic;
      final topic = referenceTopic == null
          ? null
          : module.topicByReference(referenceTopic);
      if (topic != null) {
        final relativeRoot = p.relative(topic.topicRoot, from: module.rootPath);
        if (relativeRoot != '.' && !relativeRoot.startsWith('../')) {
          topicsRootDir = relativeRoot;
        }
      }
    }
    final result = await writersideTopicCreator.create(
      WritersideTopicCreateTarget(
        rootPath: module.rootPath,
        treePath: instance.sourceTreePath,
        topicsRootDir: topicsRootDir,
        existingTopicIds: {for (final topic in module.topics) topic.id},
      ),
      request,
    );
    return _openWriterside(module.rootPath, activeFilePath: result.topicPath);
  }

  Future<List<WritersideMarkdownImportCandidate>>
  discoverWritersideMarkdownImport(String sourceDirectoryPath) {
    return writersideInstanceService.discoverMarkdownFiles(sourceDirectoryPath);
  }

  Future<WritersideInstanceMutationResult> createWritersideInstance(
    Workspace workspace,
    WritersideInstanceCreateRequest request,
  ) async {
    final module = await _currentWritersideModule(workspace);
    return writersideInstanceService.create(module: module, request: request);
  }

  Future<WritersideInstanceMutationResult> updateWritersideInstance(
    Workspace workspace,
    WritersideInstanceUpdateRequest request,
  ) async {
    final module = await _currentWritersideModule(workspace);
    return writersideInstanceService.update(module: module, request: request);
  }

  Future<void> moveWritersideTocEntry(
    Workspace workspace, {
    required String treePath,
    required List<int> sourcePath,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? sourceIdentity,
    WritersideTocNodeIdentity? referenceIdentity,
  }) async {
    final module = await _currentWritersideModule(workspace);
    final instance = _writersideInstanceForTree(module, treePath);
    await writersideTocEditor.moveSubtree(
      WritersideTocEditTarget(
        rootPath: module.rootPath,
        treePath: instance.sourceTreePath,
      ),
      WritersideTocMoveRequest(
        sourcePath: sourcePath,
        placement: placement,
        referencePath: referencePath,
        sourceIdentity: sourceIdentity,
        referenceIdentity: referenceIdentity,
      ),
    );
  }

  Future<void> moveWritersideTocEntries(
    Workspace workspace, {
    required String treePath,
    required List<WritersideTocMoveEntry> sources,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
    WritersideTocNodeIdentity? referenceIdentity,
  }) async {
    final module = await _currentWritersideModule(workspace);
    final instance = _writersideInstanceForTree(module, treePath);
    await writersideTocEditor.moveSubtrees(
      WritersideTocEditTarget(
        rootPath: module.rootPath,
        treePath: instance.sourceTreePath,
      ),
      WritersideTocBatchMoveRequest(
        sources: sources,
        placement: placement,
        referencePath: referencePath,
        referenceIdentity: referenceIdentity,
      ),
    );
  }

  Future<void> removeWritersideTocEntry(
    Workspace workspace, {
    required String treePath,
    required List<int> nodePath,
    WritersideTocNodeIdentity? expectedIdentity,
  }) async {
    final module = await _currentWritersideModule(workspace);
    final instance = _writersideInstanceForTree(module, treePath);
    await writersideTocEditor.removeEntry(
      WritersideTocEditTarget(
        rootPath: module.rootPath,
        treePath: instance.sourceTreePath,
      ),
      nodePath,
      expectedIdentity: expectedIdentity,
    );
  }

  Future<void> removeWritersideTocEntries(
    Workspace workspace, {
    required String treePath,
    required List<WritersideTocRemovalRequest> requests,
  }) async {
    final module = await _currentWritersideModule(workspace);
    final instance = _writersideInstanceForTree(module, treePath);
    await writersideTocEditor.removeEntries(
      WritersideTocEditTarget(
        rootPath: module.rootPath,
        treePath: instance.sourceTreePath,
      ),
      requests,
    );
  }

  Future<String> renameWritersideTopicFile(
    Workspace workspace,
    String topicPath,
    String newFileName,
  ) async {
    final module = await _currentWritersideModule(workspace);
    final topic = _writersideTopicForPath(module, topicPath);
    final result = await writersideTopicFileEditor.rename(
      module: module,
      topic: topic,
      newFileName: newFileName,
    );
    return result.newTopicPath;
  }

  Future<void> deleteWritersideTopicFile(
    Workspace workspace,
    String topicPath,
  ) async {
    final module = await _currentWritersideModule(workspace);
    final topic = _writersideTopicForPath(module, topicPath);
    final analysis = await writersideTopicRemovalService.analyze(
      module: module,
      topicPath: topic.filePath,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    await writersideTopicRemovalService.apply(
      WritersideTopicRemovalRequest(
        analysis: analysis,
        updateUsagesAutomatically: analysis.canUpdateUsagesAutomatically,
      ),
    );
  }

  Future<WritersideTopicRemovalAnalysis> analyzeWritersideTopicRemoval(
    Workspace workspace, {
    required String topicPath,
    required WritersideTopicRemovalMode mode,
    String? treePath,
    List<int>? nodePath,
  }) async {
    final module = await _currentWritersideModule(workspace);
    final topic = _writersideTopicForPath(module, topicPath);
    return writersideTopicRemovalService.analyze(
      module: module,
      topicPath: topic.filePath,
      mode: mode,
      selectedTreePath: treePath,
      selectedNodePath: nodePath,
    );
  }

  Future<WritersideTopicRemovalResult> applyWritersideTopicRemoval(
    Workspace workspace,
    WritersideTopicRemovalRequest request,
  ) async {
    final module = await _currentWritersideModule(workspace);
    if (!p.equals(module.rootPath, request.analysis.moduleRoot)) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    return writersideTopicRemovalService.apply(request);
  }

  WritersideModule _writersideModule(Workspace workspace) {
    if (workspace.kind != WorkspaceKind.writersideModule ||
        workspace.writersideModule == null) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    return workspace.writersideModule!;
  }

  Future<Workspace> selectWritersideContext(
    Workspace workspace, {
    required String moduleId,
    String? instanceId,
  }) async {
    final project = workspace.writersideProject;
    if (project == null) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    final selectedProject = project.withSelection(
      moduleId: moduleId,
      instanceId: instanceId,
    );
    final module = selectedProject.activeModule;
    if (module == null ||
        (instanceId != null &&
            !module.instances.any((instance) => instance.id == instanceId))) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    final selectedInstance = selectedProject.activeInstance;
    final activeFile =
        (selectedInstance?.startPage == null
            ? null
            : module
                  .topicByReference(selectedInstance!.startPage!)
                  ?.filePath) ??
        _startTopicPath(module) ??
        (module.topics.isEmpty ? null : module.topics.first.filePath);
    return workspace.copyWith(
      activeFilePath: activeFile,
      activeFileSnapshot: activeFile == null
          ? null
          : await fileSnapshot(activeFile),
      openFilePaths: activeFile == null
          ? workspace.openFilePaths
          : [...workspace.openFilePaths, activeFile],
      diagnostics: selectedProject.diagnostics,
      markdown: module.topics
          .where((topic) => topic.filePath == activeFile)
          .map((topic) => topic.markdown)
          .whereType<ParsedMarkdownDocument>()
          .firstOrNull,
      writersideModule: module,
      writersideProject: selectedProject,
    );
  }

  Future<WritersideModule> _currentWritersideModule(Workspace workspace) async {
    final openedModule = _writersideModule(workspace);
    return _loadWritersideModule(openedModule.rootPath);
  }

  Future<WritersideModule> _loadWritersideModule(String rootPath) {
    return writersideService.load(
      rootPath,
      options: _useWorkspaceScanOptionsForWriterside ? scanOptions : null,
    );
  }

  WritersideInstance _writersideInstanceForTree(
    WritersideModule module,
    String? treePath,
  ) {
    if (module.instances.isEmpty) {
      throw const BusyMarkException('writerside.topic.instance-tree-missing');
    }
    if (treePath == null) {
      return module.instances
              .where((instance) => !instance.isLibrary)
              .firstOrNull ??
          module.instances.first;
    }
    for (final instance in module.instances) {
      if (p.equals(instance.sourceTreePath, treePath)) {
        return instance;
      }
    }
    throw const BusyMarkException('writerside.topic.instance-tree-missing');
  }

  WritersideTopic _writersideTopicForPath(
    WritersideModule module,
    String topicPath,
  ) {
    for (final topic in module.topics) {
      if (p.equals(topic.filePath, topicPath)) {
        return topic;
      }
    }
    throw BusyMarkException(
      'writerside.topic-file.topic-not-resolved',
      args: {'path': topicPath},
    );
  }

  void _logOpenPathDiagnostics(
    String rawPath,
    String normalizedPath,
    FileSystemEntityType fileType,
  ) {
    busyMarkDebugLogLines([
      '[BusyMark] Open path requested',
      '[BusyMark]   raw: ${busyMarkLogPath(rawPath)}',
      '[BusyMark]   normalized: ${busyMarkLogPath(normalizedPath)}',
      '[BusyMark]   raw startsWith file://: ${isFileUriPath(rawPath)}',
      '[BusyMark]   raw startsWith /run/user/: ${rawPath.startsWith('/run/user/')}',
      '[BusyMark]   normalized startsWith /run/user/: ${normalizedPath.startsWith('/run/user/')}',
      '[BusyMark]   entity type: ${_fileTypeLabel(fileType)}',
    ]);
  }

  String _fileTypeLabel(FileSystemEntityType type) {
    if (type == FileSystemEntityType.file) {
      return 'file';
    }
    if (type == FileSystemEntityType.directory) {
      return 'directory';
    }
    if (type == FileSystemEntityType.link) {
      return 'link';
    }
    if (type == FileSystemEntityType.notFound) {
      return 'notFound';
    }
    return type.toString();
  }

  Future<String> loadText(String path) async {
    return (await loadTextWithSnapshot(path)).text;
  }

  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final stat = await file.stat();
    final decoded = decodeUtf8Document(bytes);
    return WorkspaceFileLoad(
      text: decoded.text,
      snapshot: _snapshotFromBytes(stat, bytes),
      format: decoded.format,
    );
  }

  Future<DateTime> fileModifiedAt(String path) async {
    return (await File(path).stat()).modified;
  }

  Future<WorkspaceFileSnapshot> fileSnapshot(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final stat = await file.stat();
    return _snapshotFromBytes(stat, bytes);
  }

  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    if (knownSnapshot == null) {
      return true;
    }
    try {
      final current = await fileSnapshot(path);
      return current.differsFrom(knownSnapshot);
    } on Object {
      return true;
    }
  }

  Future<bool> pathExists(String path) async {
    return await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  /// Saves a newly named file without replacing any existing filesystem
  /// entity at [path].
  ///
  /// The complete contents are staged in a private temporary directory, then
  /// published with Linux's atomic no-replace rename operation (or an atomic
  /// hard-link fallback). It fails if any filesystem entity already has the
  /// final name.
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) {
    return saveNewFormattedText(path, text);
  }

  Future<WorkspaceFileSnapshot> saveNewFormattedText(
    String path,
    String text, {
    TextFormatMetadata? format,
    LineEndingNormalization? mixedNormalization,
  }) async {
    final bytes = _encodeDocumentText(
      text,
      format: format,
      mixedNormalization: mixedNormalization,
    );
    final staged = await _stageNewSave(path, bytes);
    try {
      final stat = await staged.file.stat();
      await _beforeNewFilePublish?.call(path);
      await _publishNewFileWithoutReplace(staged.file, path);
      return _snapshotFromBytes(stat, bytes);
    } finally {
      await _deleteStagedSaveBestEffort(staged);
    }
  }

  /// Replaces the exact final directory entry at [path] without following a
  /// final symlink. This is used only after the user confirms a Save As
  /// overwrite for that displayed path.
  Future<WorkspaceFileSnapshot> saveTextReplacingPath(
    String path,
    String text,
  ) {
    return saveFormattedTextReplacingPath(path, text);
  }

  Future<WorkspaceFileSnapshot> saveFormattedTextReplacingPath(
    String path,
    String text, {
    TextFormatMetadata? format,
    LineEndingNormalization? mixedNormalization,
  }) async {
    final bytes = _encodeDocumentText(
      text,
      format: format,
      mixedNormalization: mixedNormalization,
    );
    final staged = await _stageNewSave(path, bytes);
    try {
      final targetType = await FileSystemEntity.type(path, followLinks: false);
      if (targetType == FileSystemEntityType.file) {
        await _copyFileMode(await File(path).stat(), staged.file);
      }
      final target = File(p.absolute(path));
      await staged.file.rename(target.path);
      return _snapshotFromBytes(await target.stat(), bytes);
    } finally {
      await _deleteStagedSaveBestEffort(staged);
    }
  }

  Future<WorkspaceFileSnapshot> saveText(String path, String text) {
    return saveFormattedText(path, text);
  }

  Future<WorkspaceFileSnapshot> saveFormattedText(
    String path,
    String text, {
    TextFormatMetadata? format,
    LineEndingNormalization? mixedNormalization,
  }) async {
    final savePath = await _saveTargetPath(path);
    final target = File(savePath);
    final existingStat = await target.stat();
    final bytes = _encodeDocumentText(
      text,
      format: format,
      mixedNormalization: mixedNormalization,
    );
    final temp = _temporarySaveFile(savePath);
    var renamed = false;
    try {
      await temp.writeAsBytes(bytes, flush: true);
      if (existingStat.type != FileSystemEntityType.notFound) {
        await _copyFileMode(existingStat, temp);
      }
      await temp.rename(savePath);
      renamed = true;
      final stat = await target.stat();
      return _snapshotFromBytes(stat, bytes);
    } on Object {
      if (!renamed) {
        await _deleteSaveArtifactBestEffort(temp);
      }
      rethrow;
    }
  }

  /// Replaces a group of existing files as one recoverable transaction.
  ///
  /// Every source snapshot is checked before any target is changed. Staged
  /// files are atomically exchanged with their targets; if a later exchange
  /// fails, already-exchanged files are rolled back.
  Future<Map<String, WorkspaceFileSnapshot>> saveFormattedTextBatch(
    List<WorkspaceBatchTextWrite> writes,
  ) async {
    if (writes.isEmpty) {
      return const {};
    }
    if (!Platform.isLinux || !LinuxAtomicFileApi.instance.isAvailable) {
      throw UnsupportedError(
        'Transactional workspace replacement requires Linux renameat2.',
      );
    }
    final paths = <String>{};
    final staged = <_StagedBatchTextWrite>[];
    final committed = <_StagedBatchTextWrite>[];
    final preservedArtifacts = <String>{};
    try {
      for (final write in writes) {
        final savePath = await _saveTargetPath(write.path);
        if (!paths.add(p.normalize(p.absolute(savePath)))) {
          throw ArgumentError('Duplicate batch write path: ${write.path}');
        }
        final target = File(savePath);
        final originalBytes = await target.readAsBytes();
        final originalStat = await target.stat();
        final originalSnapshot = _snapshotFromBytes(
          originalStat,
          originalBytes,
        );
        if (originalSnapshot.differsFrom(write.expectedSnapshot)) {
          throw WorkspaceBatchWriteConflict(write.path);
        }
        final bytes = _encodeDocumentText(
          write.text,
          format: write.format,
          mixedNormalization: write.mixedNormalization,
        );
        final directory = await target.parent.createTemp(
          '.busymark-save-batch-',
        );
        final stagedFile = File(p.join(directory.path, 'contents'));
        await stagedFile.writeAsBytes(bytes, flush: true);
        await _copyFileMode(originalStat, stagedFile);
        staged.add(
          _StagedBatchTextWrite(
            requestPath: write.path,
            target: target,
            directory: directory,
            stagedFile: stagedFile,
            expectedSnapshot: write.expectedSnapshot,
            bytes: bytes,
          ),
        );
      }
      // Close the validation/staging race before the first exchange.
      for (final write in staged) {
        final current = await fileSnapshot(write.target.path);
        if (current.differsFrom(write.expectedSnapshot)) {
          throw WorkspaceBatchWriteConflict(write.requestPath);
        }
      }
      for (final write in staged) {
        final error = LinuxAtomicFileApi.instance.exchange(
          write.stagedFile.absolute.path,
          write.target.absolute.path,
        );
        if (error != null) {
          throw FileSystemException(
            'Could not commit workspace replacement batch',
            write.requestPath,
            OSError('atomic exchange failed', error),
          );
        }
        final displacedBytes = await write.stagedFile.readAsBytes();
        final displacedSnapshot = _snapshotFromBytes(
          await write.stagedFile.stat(),
          displacedBytes,
        );
        if (displacedSnapshot.differsFrom(write.expectedSnapshot)) {
          final conflict = await _rollbackBatchWrite(write);
          if (conflict != null) {
            preservedArtifacts.add(conflict.preservedPath);
            throw WorkspaceBatchPartialApplicationConflict(
              files: [conflict],
              cause: WorkspaceBatchWriteConflict(write.requestPath),
            );
          }
          throw WorkspaceBatchWriteConflict(write.requestPath);
        }
        committed.add(write);
        await _afterBatchFileCommit?.call(write.target.path, committed.length);
      }
      return {
        for (final write in staged)
          write.requestPath: _snapshotFromBytes(
            await write.target.stat(),
            write.bytes,
          ),
      };
    } on Object catch (error, stackTrace) {
      final conflicts = <WorkspaceBatchPartialApplicationFile>[
        if (error case WorkspaceBatchPartialApplicationConflict partial)
          ...partial.files,
      ];
      preservedArtifacts.addAll(
        conflicts.map((conflict) => conflict.preservedPath),
      );
      for (final write in committed.reversed) {
        final conflict = await _rollbackBatchWrite(write);
        if (conflict != null) {
          conflicts.add(conflict);
          preservedArtifacts.add(conflict.preservedPath);
        }
      }
      if (conflicts.isNotEmpty) {
        throw WorkspaceBatchPartialApplicationConflict(
          files: List.unmodifiable(conflicts),
          cause: error is WorkspaceBatchPartialApplicationConflict
              ? error.cause
              : error,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      for (final write in staged) {
        if (preservedArtifacts.contains(write.stagedFile.path)) {
          continue;
        }
        await _deleteSaveArtifactBestEffort(write.stagedFile);
        try {
          if (await write.directory.exists()) {
            await write.directory.delete();
          }
        } on Object {
          // Cleanup must not hide a commit or rollback result.
        }
      }
    }
  }

  Future<WorkspaceBatchPartialApplicationFile?> _rollbackBatchWrite(
    _StagedBatchTextWrite write,
  ) async {
    final conflict = WorkspaceBatchPartialApplicationFile(
      targetPath: write.requestPath,
      preservedPath: write.stagedFile.path,
    );
    if (!await _fileMatchesBytes(write.target, write.bytes)) {
      return conflict;
    }
    final rollbackError = LinuxAtomicFileApi.instance.exchange(
      write.stagedFile.absolute.path,
      write.target.absolute.path,
    );
    if (rollbackError != null) {
      return conflict;
    }
    if (await _fileMatchesBytes(write.stagedFile, write.bytes)) {
      return null;
    }

    // The target changed after validation but before the exchange. Put that
    // concurrent version back when possible, and preserve the displaced data.
    LinuxAtomicFileApi.instance.exchange(
      write.stagedFile.absolute.path,
      write.target.absolute.path,
    );
    return conflict;
  }

  Future<bool> _fileMatchesBytes(File file, List<int> expected) async {
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        return false;
      }
      final actual = await file.readAsBytes();
      return actual.length == expected.length &&
          crypto.sha256.convert(actual) == crypto.sha256.convert(expected);
    } on Object {
      return false;
    }
  }

  Future<String> createFile(
    Workspace workspace,
    String directoryPath,
    String fileName,
  ) async {
    final anchor = await _workspacePathAnchor(workspace);
    final directory = await _safeWorkspaceDirectory(anchor, directoryPath);
    final target = await _safeWorkspaceChildPath(
      anchor,
      p.join(directory, _safeEntityName(fileName)),
      allowRoot: false,
    );
    await _ensurePathAvailable(anchor, target);
    await File(target).create(exclusive: true);
    return target;
  }

  Future<String> renameEntity(
    Workspace workspace,
    String sourcePath,
    String newName,
  ) async {
    final anchor = await _workspacePathAnchor(workspace);
    final source = await _safeWorkspaceChildPath(
      anchor,
      sourcePath,
      allowRoot: false,
      allowFinalSymlink: true,
      allowMissingAncestors: true,
    );
    final target = await _safeWorkspaceChildPath(
      anchor,
      p.join(p.dirname(source), _safeEntityName(newName)),
      allowRoot: false,
      allowMissingAncestors: true,
    );
    if (p.equals(source, target)) {
      return source;
    }
    await _renameEntity(anchor, source, target);
    return target;
  }

  Future<String> moveEntity(
    Workspace workspace,
    String sourcePath,
    String targetDirectoryPath,
  ) async {
    final anchor = await _workspacePathAnchor(workspace);
    final source = await _safeWorkspaceChildPath(
      anchor,
      sourcePath,
      allowRoot: false,
      allowFinalSymlink: true,
      allowMissingAncestors: true,
    );
    final directory = await _safeWorkspaceDirectory(
      anchor,
      targetDirectoryPath,
    );
    if (p.equals(p.dirname(source), directory)) {
      return source;
    }
    if (p.isWithin(source, directory)) {
      throw BusyMarkException(
        'workspace.file-operation-invalid-target',
        args: {'path': directory},
      );
    }
    final target = await _safeWorkspaceChildPath(
      anchor,
      p.join(directory, p.basename(source)),
      allowRoot: false,
    );
    await _renameEntity(anchor, source, target);
    return target;
  }

  Future<void> deleteEntity(Workspace workspace, String sourcePath) async {
    final anchor = await _workspacePathAnchor(workspace);
    final source = await _safeWorkspaceChildPath(
      anchor,
      sourcePath,
      allowRoot: false,
      allowFinalSymlink: true,
      allowMissingAncestors: true,
    );
    final resolution = await _resolveWorkspacePath(
      anchor,
      source,
      allowRoot: false,
      allowFinalSymlink: true,
      allowMissingAncestors: true,
    );
    final type = resolution.type;
    if (workspace.kind == WorkspaceKind.writersideModule &&
        await _containsWritersideTopic(workspace, source, type)) {
      throw const BusyMarkException(
        'writerside.topic-removal.safe-delete-required',
      );
    }
    if (type == FileSystemEntityType.directory) {
      await Directory(source).delete(recursive: true);
      return;
    }
    if (type == FileSystemEntityType.file) {
      await File(source).delete();
      return;
    }
    if (type == FileSystemEntityType.link) {
      await Link(source).delete();
      return;
    }
    throw BusyMarkException(
      'workspace.path-does-not-exist',
      args: {'path': source},
    );
  }

  Future<bool> _containsWritersideTopic(
    Workspace workspace,
    String sourcePath,
    FileSystemEntityType type,
  ) async {
    final module = await _currentWritersideModule(workspace);
    for (final configuredRoot in module.config.topicRoots) {
      final topicRoot = p.normalize(
        p.join(module.rootPath, configuredRoot.dir),
      );
      if (type == FileSystemEntityType.directory &&
          (p.equals(sourcePath, topicRoot) ||
              p.isWithin(topicRoot, sourcePath) ||
              p.isWithin(sourcePath, topicRoot))) {
        return true;
      }
      final extension = p.extension(sourcePath).toLowerCase();
      if (type == FileSystemEntityType.file &&
          p.isWithin(topicRoot, sourcePath) &&
          (extension == '.md' ||
              extension == '.markdown' ||
              extension == '.topic')) {
        return true;
      }
    }
    for (final topic in module.topics) {
      final topicPath = p.normalize(topic.filePath);
      if (p.equals(topicPath, sourcePath) ||
          (type == FileSystemEntityType.directory &&
              p.isWithin(sourcePath, topicPath))) {
        return true;
      }
    }
    return false;
  }

  Future<CanonicalPathAnchor> _workspacePathAnchor(Workspace workspace) async {
    try {
      final anchor = await captureCanonicalDirectoryAnchor(workspace.rootPath);
      if (!p.equals(anchor.requestedRootPath, anchor.rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootReplacement,
          path: anchor.requestedRootPath,
        );
      }
      return anchor;
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'workspace.file-operation-outside-root',
        args: {'path': error.path},
      );
    }
  }

  Future<String> _safeWorkspaceChildPath(
    CanonicalPathAnchor anchor,
    String path, {
    required bool allowRoot,
    bool allowFinalSymlink = false,
    bool allowMissingAncestors = false,
  }) async {
    return (await _resolveWorkspacePath(
      anchor,
      path,
      allowRoot: allowRoot,
      allowFinalSymlink: allowFinalSymlink,
      allowMissingAncestors: allowMissingAncestors,
    )).path;
  }

  Future<AnchoredPathResolution> _resolveWorkspacePath(
    CanonicalPathAnchor anchor,
    String path, {
    required bool allowRoot,
    bool allowFinalSymlink = false,
    bool allowMissingAncestors = false,
  }) async {
    final normalized = normalizePath(path);
    final isRoot =
        p.equals(normalized, anchor.requestedRootPath) ||
        p.equals(normalized, anchor.rootPath);
    if (!allowRoot && isRoot) {
      throw BusyMarkException(
        'workspace.file-operation-root',
        args: {'path': normalized},
      );
    }
    try {
      return await resolveAnchoredPath(
        anchor,
        normalized,
        allowRoot: allowRoot,
        allowFinalSymlink: allowFinalSymlink,
        allowMissingAncestors: allowMissingAncestors,
      );
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'workspace.file-operation-outside-root',
        args: {'path': error.path},
      );
    }
  }

  Future<String> _safeWorkspaceDirectory(
    CanonicalPathAnchor anchor,
    String path,
  ) async {
    final resolution = await _resolveWorkspacePath(
      anchor,
      path,
      allowRoot: true,
      allowMissingAncestors: true,
    );
    if (resolution.type != FileSystemEntityType.directory) {
      throw BusyMarkException(
        'workspace.directory-missing',
        args: {'path': resolution.path},
      );
    }
    return resolution.path;
  }

  String _safeEntityName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const BusyMarkException('workspace.file-name-required');
    }
    if (trimmed == '.' ||
        trimmed == '..' ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        p.basename(trimmed) != trimmed) {
      throw BusyMarkException(
        'workspace.file-name-unsafe',
        args: {'name': trimmed},
      );
    }
    return trimmed;
  }

  Future<void> _ensurePathAvailable(
    CanonicalPathAnchor anchor,
    String path,
  ) async {
    final resolution = await _resolveWorkspacePath(
      anchor,
      path,
      allowRoot: false,
    );
    if (resolution.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'workspace.path-already-exists',
        args: {'path': resolution.path},
      );
    }
  }

  Future<void> _renameEntity(
    CanonicalPathAnchor anchor,
    String source,
    String target,
  ) async {
    final sourceResolution = await _resolveWorkspacePath(
      anchor,
      source,
      allowRoot: false,
      allowFinalSymlink: true,
      allowMissingAncestors: true,
    );
    final type = sourceResolution.type;
    if (type != FileSystemEntityType.directory &&
        type != FileSystemEntityType.file &&
        type != FileSystemEntityType.link) {
      throw BusyMarkException(
        'workspace.path-does-not-exist',
        args: {'path': sourceResolution.path},
      );
    }
    await _ensurePathAvailable(anchor, target);
    if (type == FileSystemEntityType.directory) {
      await Directory(sourceResolution.path).rename(target);
      return;
    }
    if (type == FileSystemEntityType.file) {
      await File(sourceResolution.path).rename(target);
      return;
    }
    if (type == FileSystemEntityType.link) {
      await Link(sourceResolution.path).rename(target);
      return;
    }
    throw StateError('Unsupported workspace entity type: $type');
  }

  Future<String> _saveTargetPath(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.link) {
      return path;
    }
    return Link(path).resolveSymbolicLinks();
  }

  Future<void> _copyFileMode(FileStat sourceStat, File target) async {
    if (Platform.isWindows) {
      return;
    }
    final mode = (sourceStat.mode & 0xfff).toRadixString(8);
    final result = await Process.run('chmod', [mode, target.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Failed to apply file mode $mode: ${result.stderr}',
        target.path,
      );
    }
  }

  WorkspaceFileSnapshot _snapshotFromBytes(FileStat stat, List<int> bytes) {
    return WorkspaceFileSnapshot(
      modifiedAt: stat.modified,
      size: stat.size,
      contentHash: crypto.sha256.convert(bytes).toString(),
    );
  }

  Future<_StagedSave> _stageNewSave(String path, List<int> bytes) async {
    final directory = await Directory(
      p.dirname(p.absolute(path)),
    ).createTemp('.busymark-save-');
    final staged = _StagedSave(
      directory: directory,
      file: File(p.join(directory.path, 'contents')),
    );
    try {
      await staged.file.writeAsBytes(bytes, flush: true);
      return staged;
    } on Object {
      await _deleteStagedSaveBestEffort(staged);
      rethrow;
    }
  }

  Future<void> _publishNewFileWithoutReplace(
    File stagedFile,
    String targetPath,
  ) async {
    if (!Platform.isLinux) {
      throw UnsupportedError(
        'Atomic no-replace publication is currently supported on Linux only.',
      );
    }
    final errorNumber = LinuxAtomicFileApi.instance.publishNoReplace(
      stagedFile.absolute.path,
      File(targetPath).absolute.path,
    );
    if (errorNumber == null) {
      return;
    }
    if (errorNumber == LinuxAtomicFileApi.fileExistsError) {
      throw BusyMarkException(
        'workspace.path-already-exists',
        args: {'path': targetPath},
      );
    }
    throw FileSystemException(
      'Failed to atomically publish the new file',
      targetPath,
      OSError('no-replace publication failed', errorNumber),
    );
  }

  Future<void> _deleteStagedSaveBestEffort(_StagedSave staged) async {
    await _deleteSaveArtifactBestEffort(staged.file);
    try {
      if (await staged.directory.exists()) {
        await staged.directory.delete();
      }
    } on Object {
      // Best-effort cleanup; preserve the original save result or error.
    }
  }

  File _temporarySaveFile(String path) {
    final directory = p.dirname(path);
    final basename = p.basename(path);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return File(p.join(directory, '.$basename.busymark-save-$pid-$stamp.tmp'));
  }

  Future<void> _deleteSaveArtifactBestEffort(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on Object {
      // Best-effort cleanup; preserve the original save error.
    }
  }

  Future<Workspace> reparseActive(Workspace workspace, String source) async {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return workspace;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final module = workspace.writersideModule;
      final topic = module?.topics
          .where((item) => item.filePath == active)
          .firstOrNull;
      if (topic?.format == WritersideTopicFormat.markdown) {
        final parsed =
            WritersideTopicParser(
              markdownParser: markdownParser,
              documentParser: writersideService.topicParser.documentParser,
            ).parseMarkdown(
              filePath: active,
              source: source,
              topicsRoot: topic!.topicRoot,
            );
        return _workspaceWithReparsedWritersideTopic(
          workspace,
          module!,
          topic,
          parsed,
        );
      }
      if (topic?.format == WritersideTopicFormat.xml) {
        final parsed = writersideService.topicParser.parseXml(
          filePath: active,
          source: source,
          topicsRoot: topic!.topicRoot,
        );
        return _workspaceWithReparsedWritersideTopic(
          workspace,
          module!,
          topic,
          parsed,
        );
      }
      if (module != null && _isWritersideProjectFile(module, active)) {
        final updatedModule = await writersideService.load(
          module.rootPath,
          options: _useWorkspaceScanOptionsForWriterside ? scanOptions : null,
          sourceOverrides: {
            ...module.sourceOverrides,
            normalizePath(active): source,
          },
        );
        return _workspaceWithReparsedWritersideModule(
          workspace,
          module,
          updatedModule,
          rediscoverFileSymbols: p.equals(active, module.config.filePath),
        );
      }
      return workspace;
    }
    final markdown = await markdownParser.parseAsync(
      filePath: active,
      source: source,
      mode: MarkdownMode.commonMark,
      workspaceRoot: workspace.rootPath,
    );
    return workspace.copyWith(
      markdown: markdown,
      diagnostics: markdown.diagnostics,
    );
  }

  Workspace _workspaceWithReparsedWritersideTopic(
    Workspace workspace,
    WritersideModule module,
    WritersideTopic previousTopic,
    WritersideTopic parsedTopic,
  ) {
    final activePath = parsedTopic.filePath;
    final updatedModule = module.copyWith(
      topics: List.unmodifiable([
        for (final topic in module.topics)
          if (p.equals(topic.filePath, activePath)) parsedTopic else topic,
      ]),
      diagnostics: sortDiagnostics([
        for (final diagnostic in module.diagnostics)
          if (!p.equals(diagnostic.filePath, activePath)) diagnostic,
        ...parsedTopic.diagnostics,
      ]),
      sourceOverrides: {
        ...module.sourceOverrides,
        normalizePath(activePath): parsedTopic.document.source,
      },
    );
    final previousProject = workspace.writersideProject;
    final updatedProject = previousProject?.withModule(updatedModule);
    final indexedWorkspace = workspace.copyWith(
      markdown: parsedTopic.markdown,
      writersideModule: updatedProject?.activeModule ?? updatedModule,
      writersideProject: updatedProject,
    );
    final resolutionDiagnostics = _writersideResolutionDiagnostics(
      indexedWorkspace,
      indexedWorkspace.writersideModule!,
      parsedTopic,
    );
    final previousResolutionDiagnostics = _writersideResolutionDiagnostics(
      workspace,
      module,
      previousTopic,
    );
    final preservedWorkspaceDiagnostics = [
      for (final diagnostic in workspace.diagnostics)
        if (!_isProjectDiagnostic(previousProject, diagnostic) &&
            !p.equals(diagnostic.filePath, activePath) &&
            !previousResolutionDiagnostics.any(
              (previous) => _sameDiagnostic(previous, diagnostic),
            ))
          diagnostic,
    ];
    return indexedWorkspace.copyWith(
      diagnostics: sortDiagnostics([
        ...?updatedProject?.diagnostics,
        if (updatedProject == null) ...updatedModule.diagnostics,
        ...preservedWorkspaceDiagnostics,
        ...resolutionDiagnostics,
      ]),
    );
  }

  Future<Workspace> _workspaceWithReparsedWritersideModule(
    Workspace workspace,
    WritersideModule previousModule,
    WritersideModule updatedModule, {
    required bool rediscoverFileSymbols,
  }) async {
    final previousProject = workspace.writersideProject;
    final updatedProject = previousProject == null
        ? null
        : await _writersideProjectService.replaceModule(
            previousProject,
            updatedModule,
            rediscoverFileSymbols: rediscoverFileSymbols,
          );
    final previousResolutionDiagnostics = [
      for (final topic in previousModule.topics)
        ..._writersideResolutionDiagnostics(workspace, previousModule, topic),
    ];
    final preservedWorkspaceDiagnostics = [
      for (final diagnostic in workspace.diagnostics)
        if (!_isProjectDiagnostic(previousProject, diagnostic) &&
            !previousModule.diagnostics.any(
              (candidate) => identical(candidate, diagnostic),
            ) &&
            !previousResolutionDiagnostics.any(
              (previous) => _sameDiagnostic(previous, diagnostic),
            ))
          diagnostic,
    ];
    return workspace.copyWith(
      markdown: null,
      writersideModule: updatedProject?.activeModule ?? updatedModule,
      writersideProject: updatedProject,
      diagnostics: sortDiagnostics([
        ...?updatedProject?.diagnostics,
        if (updatedProject == null) ...updatedModule.diagnostics,
        ...preservedWorkspaceDiagnostics,
      ]),
    );
  }

  bool _isWritersideProjectFile(WritersideModule module, String filePath) {
    final config = module.config;
    final candidates = <String>{
      config.filePath,
      for (final instance in module.instances) instance.sourceTreePath,
      for (final instance in config.instances)
        _moduleConfiguredPath(module.rootPath, instance.src),
      if (config.varsFile case final path?)
        _moduleConfiguredPath(module.rootPath, path),
      if (config.categoriesFile case final path?)
        _moduleConfiguredPath(module.rootPath, path),
      if (config.instanceGroupsFile case final path?)
        _moduleConfiguredPath(module.rootPath, path),
      _moduleConfiguredPath(
        module.rootPath,
        p.join(config.buildConfigDir, 'buildprofiles.xml'),
      ),
    };
    return candidates.any((candidate) => p.equals(candidate, filePath));
  }

  String _moduleConfiguredPath(String rootPath, String configuredPath) {
    return normalizePath(
      p.isAbsolute(configuredPath)
          ? configuredPath
          : p.join(rootPath, configuredPath),
    );
  }

  bool _isProjectDiagnostic(
    WritersideProject? project,
    Diagnostic diagnostic,
  ) =>
      project?.diagnostics.any(
        (candidate) => identical(candidate, diagnostic),
      ) ??
      false;

  bool _sameDiagnostic(Diagnostic first, Diagnostic second) {
    return first.code == second.code &&
        first.severity == second.severity &&
        p.equals(first.filePath, second.filePath) &&
        first.sourceSpan?.startOffset == second.sourceSpan?.startOffset &&
        first.sourceSpan?.endOffset == second.sourceSpan?.endOffset;
  }

  PreviewDocument? buildPreview(Workspace workspace, String source) {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return null;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      return _buildWritersidePreview(workspace, active, source);
    }
    final currentMarkdown = workspace.markdown;
    if (currentMarkdown != null &&
        p.equals(currentMarkdown.filePath, active) &&
        currentMarkdown.source == source) {
      return previewBuilder.build(currentMarkdown);
    }
    final parsed = markdownParser.parse(
      filePath: active,
      source: source,
      mode: MarkdownMode.commonMark,
      workspaceRoot: workspace.rootPath,
      validateLocalReferences: false,
    );
    return previewBuilder.build(parsed);
  }

  /// Builds preview data without running Markdown parsing on Flutter's UI
  /// isolate. An already-current workspace parse is reused when available.
  Future<PreviewDocument?> buildPreviewAsync(
    Workspace workspace,
    String source,
  ) async {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return null;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      return _buildWritersidePreview(workspace, active, source);
    }
    final currentMarkdown = workspace.markdown;
    if (currentMarkdown != null &&
        p.equals(currentMarkdown.filePath, active) &&
        currentMarkdown.source == source) {
      return previewBuilder.build(currentMarkdown);
    }
    final parsed = await markdownParser.parseAsync(
      filePath: active,
      source: source,
      mode: MarkdownMode.commonMark,
      workspaceRoot: workspace.rootPath,
      validateLocalReferences: false,
    );
    return previewBuilder.build(parsed);
  }

  PreviewDocument? _buildWritersidePreview(
    Workspace workspace,
    String active,
    String source,
  ) {
    final module = workspace.writersideModule;
    if (module == null) {
      return null;
    }
    final originalTopic = module.topics
        .where((item) => item.filePath == active)
        .firstOrNull;
    if (originalTopic == null) {
      return PreviewDocument(
        title: p.basename(active),
        modeLabel: '',
        compatibility: '',
        blocks: [PreviewBlock(kind: PreviewBlockKind.code, text: source)],
      );
    }
    final topic = originalTopic.format == WritersideTopicFormat.markdown
        ? writersideService.topicParser.parseMarkdown(
            filePath: active,
            source: source,
            topicsRoot: originalTopic.topicRoot,
          )
        : writersideService.topicParser.parseXml(
            filePath: active,
            source: source,
            topicsRoot: originalTopic.topicRoot,
          );
    final instance =
        workspace.writersideProject?.activeInstance ??
        module.instances
            .where(
              (candidate) =>
                  !candidate.isLibrary &&
                  candidate.topicFileSet.any(
                    (reference) =>
                        module.topicByReference(reference)?.filePath == active,
                  ),
            )
            .firstOrNull ??
        module.instances.where((candidate) => !candidate.isLibrary).firstOrNull;
    final resolved = writersideDocumentResolver.resolve(
      topic.document,
      WritersideResolveContext(
        module: module,
        topic: topic,
        instance: instance,
        modulesByOrigin:
            workspace.writersideProject?.modulesByOrigin ??
            {if (module.config.moduleName case final name?) name: module},
      ),
    );
    return const BusyMarkPreviewBuilder().build(
      writersideDocumentRenderer.toBusyDocument(
        resolved.document,
        title: resolved.title ?? topic.title ?? topic.fileName,
      ),
    );
  }

  List<Diagnostic> _writersideResolutionDiagnostics(
    Workspace workspace,
    WritersideModule module,
    WritersideTopic topic,
  ) {
    final instance =
        workspace.writersideProject?.activeInstance ??
        module.instances
            .where(
              (candidate) =>
                  !candidate.isLibrary &&
                  candidate.topicFileSet.any(
                    (reference) =>
                        module.topicByReference(reference)?.filePath ==
                        topic.filePath,
                  ),
            )
            .firstOrNull ??
        module.instances.where((candidate) => !candidate.isLibrary).firstOrNull;
    return writersideDocumentResolver
        .resolve(
          topic.document,
          WritersideResolveContext(
            module: module,
            topic: topic,
            instance: instance,
            modulesByOrigin:
                workspace.writersideProject?.modulesByOrigin ??
                {if (module.config.moduleName case final name?) name: module},
          ),
        )
        .diagnostics;
  }

  Future<Workspace> _openSingleMarkdown(String filePath) async {
    final load = await loadTextWithSnapshot(filePath);
    final rootPath = p.dirname(filePath);
    final markdown = await markdownParser.parseAsync(
      filePath: filePath,
      source: load.text,
      workspaceRoot: rootPath,
    );
    return Workspace(
      id: filePath,
      rootPath: rootPath,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime.now(),
      activeFilePath: filePath,
      activeFileSnapshot: load.snapshot,
      openFilePaths: [filePath],
      files: [await _documentFile(filePath, rootPath)],
      diagnostics: markdown.diagnostics,
      markdown: markdown,
    );
  }

  Future<Workspace> _openMarkdownFolder(String rootPath) async {
    final scan = await scanWorkspaceEntities(
      rootPath,
      options: _workspaceDisplayScanOptions,
    );
    final entities = scan.entities;
    final files = <DocumentFile>[];
    final directories = _workspaceDirectories(entities, rootPath);
    final diagnostics = <Diagnostic>[...scan.diagnostics];
    ParsedMarkdownDocument? firstMarkdown;
    var parsedDocuments = 0;
    for (final entity in entities.whereType<File>()) {
      final document = await _safeDocumentFile(
        entity.path,
        rootPath,
        diagnostics,
      );
      if (document == null) {
        continue;
      }
      files.add(document);
      if (isMarkdownPath(entity.path)) {
        final parsed = await _parseMarkdownFileIfSafe(
          entity,
          rootPath,
          diagnostics,
          parsedDocuments,
        );
        if (parsed == null) {
          continue;
        }
        parsedDocuments++;
        diagnostics.addAll(parsed.diagnostics);
        firstMarkdown ??= parsed;
      }
    }
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime.now(),
      activeFilePath: firstMarkdown?.filePath,
      activeFileSnapshot: firstMarkdown == null
          ? null
          : await fileSnapshot(firstMarkdown.filePath),
      openFilePaths: firstMarkdown == null
          ? const []
          : [firstMarkdown.filePath],
      files: files,
      directories: directories,
      diagnostics: sortDiagnostics(diagnostics),
      markdown: firstMarkdown,
    );
  }

  Future<Workspace> _openWriterside(
    String rootPath, {
    String? activeFilePath,
    String? preferredModuleRoot,
  }) async {
    final project = await _writersideProjectService.load(
      rootPath,
      preferredModuleRoot: preferredModuleRoot ?? rootPath,
    );
    final module =
        project.activeModule ?? await _loadWritersideModule(rootPath);
    final scan = await scanWorkspaceEntities(
      rootPath,
      options: _workspaceDisplayScanOptions,
    );
    final entities = scan.entities;
    final files = <DocumentFile>[];
    final directories = _workspaceDirectories(entities, rootPath);
    final diagnostics = <Diagnostic>[
      ...project.diagnostics,
      ...scan.diagnostics,
    ];
    for (final entity in entities.whereType<File>()) {
      final file = await _safeDocumentFile(entity.path, rootPath, diagnostics);
      if (file != null) {
        files.add(file);
      }
    }
    final firstTopic =
        activeFilePath ??
        _startTopicPath(module) ??
        (module.topics.isEmpty ? null : module.topics.first.filePath);
    final workspace = Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.writersideModule,
      openedAt: DateTime.now(),
      activeFilePath: firstTopic,
      activeFileSnapshot: firstTopic == null
          ? null
          : await fileSnapshot(firstTopic),
      openFilePaths: firstTopic == null ? const [] : [firstTopic],
      files: files,
      directories: directories,
      diagnostics: sortDiagnostics(diagnostics),
      writersideModule: module,
      writersideProject: project,
      markdown: module.topics
          .where((topic) => topic.filePath == firstTopic)
          .map((topic) => topic.markdown)
          .whereType<ParsedMarkdownDocument>()
          .firstOrNull,
    );
    final activeTopic = module.topics
        .where((topic) => topic.filePath == firstTopic)
        .firstOrNull;
    if (activeTopic == null) {
      return workspace;
    }
    return workspace.copyWith(
      diagnostics: sortDiagnostics([
        ...workspace.diagnostics,
        ..._writersideResolutionDiagnostics(workspace, module, activeTopic),
      ]),
    );
  }

  WritersideProjectService get _writersideProjectService =>
      WritersideProjectService(
        moduleService: writersideService,
        scanOptions: _useWorkspaceScanOptionsForWriterside
            ? scanOptions
            : writersideService.scanOptions,
      );

  String? _startTopicPath(WritersideModule module) {
    for (final instance in module.instances) {
      if (instance.isLibrary || instance.startPage == null) {
        continue;
      }
      final topic = module.topicByReference(instance.startPage!);
      if (topic != null) {
        return topic.filePath;
      }
    }
    return null;
  }

  Future<DocumentFile> _documentFile(String path, String rootPath) async {
    final stat = await File(path).stat();
    return DocumentFile(
      absolutePath: path,
      relativePath: normalizedRelative(rootPath, path),
      kind: _documentKind(path),
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  Future<DocumentFile?> _safeDocumentFile(
    String path,
    String rootPath,
    List<Diagnostic> diagnostics,
  ) async {
    try {
      return await _documentFile(path, rootPath);
    } on Object catch (error) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.stat-failed',
          severity: DiagnosticSeverity.warning,
          filePath: path,
          args: {'error': '$error'},
        ),
      );
      return null;
    }
  }

  Future<ParsedMarkdownDocument?> _parseMarkdownFileIfSafe(
    File file,
    String workspaceRoot,
    List<Diagnostic> diagnostics,
    int parsedDocuments,
  ) async {
    if (parsedDocuments >= scanOptions.maxParsedDocuments) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.scan.document-limit',
          severity: DiagnosticSeverity.warning,
          filePath: file.path,
        ),
      );
      return null;
    }
    final stat = await file.stat();
    if (stat.size > scanOptions.maxParsedFileBytes) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.too-large',
          severity: DiagnosticSeverity.warning,
          filePath: file.path,
        ),
      );
      return null;
    }
    try {
      return await markdownParser.parseAsync(
        filePath: file.path,
        source: await file.readAsString(),
        workspaceRoot: workspaceRoot,
      );
    } on Object catch (error) {
      diagnostics.add(
        Diagnostic(
          code: 'workspace.file.read-failed',
          severity: DiagnosticSeverity.warning,
          filePath: file.path,
          args: {'error': '$error'},
        ),
      );
      return null;
    }
  }

  DocumentKind _documentKind(String path) {
    final extension = p.extension(path).toLowerCase();
    if (p.basename(path) == '.gitignore') {
      return DocumentKind.gitIgnore;
    }
    if (extension == '.md' || extension == '.markdown') {
      return DocumentKind.markdown;
    }
    if (extension == '.topic') {
      return DocumentKind.writersideXmlTopic;
    }
    if (extension == '.tree') {
      return DocumentKind.tree;
    }
    if (extension == '.cfg' ||
        p.basename(path) == 'writerside.cfg' ||
        p.basename(path) == 'project.ihp') {
      return DocumentKind.config;
    }
    if (p.basename(path) == 'v.list') {
      return DocumentKind.variables;
    }
    if (p.basename(path) == 'c.list') {
      return DocumentKind.categories;
    }
    if ({
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.svg',
      '.webp',
    }.contains(extension)) {
      return DocumentKind.image;
    }
    return isTextDocumentationPath(path)
        ? DocumentKind.resource
        : DocumentKind.unknown;
  }

  WorkspaceScanOptions get _workspaceDisplayScanOptions => WorkspaceScanOptions(
    maxParsedFileBytes: scanOptions.maxParsedFileBytes,
    maxParsedDocuments: scanOptions.maxParsedDocuments,
    maxTreeEntries: scanOptions.maxTreeEntries,
    followLinks: scanOptions.followLinks,
    includeUnsupportedFiles: true,
    includeDirectories: true,
    includeHiddenDirectories: true,
    includeExcludedDirectories: true,
  );

  List<WorkspaceDirectory> _workspaceDirectories(
    List<FileSystemEntity> entities,
    String rootPath,
  ) {
    return [
      for (final entity in entities.whereType<Directory>())
        WorkspaceDirectory(
          absolutePath: entity.path,
          relativePath: normalizedRelative(rootPath, entity.path),
        ),
    ];
  }
}

List<int> _encodeDocumentText(
  String text, {
  TextFormatMetadata? format,
  LineEndingNormalization? mixedNormalization,
}) {
  return format == null
      ? utf8.encode(text)
      : format.encode(text, mixedNormalization: mixedNormalization);
}

class _StagedSave {
  const _StagedSave({required this.directory, required this.file});

  final Directory directory;
  final File file;
}

class _StagedBatchTextWrite {
  const _StagedBatchTextWrite({
    required this.requestPath,
    required this.target,
    required this.directory,
    required this.stagedFile,
    required this.expectedSnapshot,
    required this.bytes,
  });

  final String requestPath;
  final File target;
  final Directory directory;
  final File stagedFile;
  final WorkspaceFileSnapshot expectedSnapshot;
  final List<int> bytes;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
