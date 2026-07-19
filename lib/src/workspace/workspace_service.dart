import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/debug_log.dart';
import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_module_service.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_project_creator.dart';
import '../writerside/writerside_topic_creator.dart';
import 'workspace_model.dart';

class WorkspaceService {
  const WorkspaceService({
    this.markdownParser = const MarkdownParser(),
    this.previewBuilder = const MarkdownPreviewBuilder(),
    this.writersideService = const WritersideModuleService(),
    this.writersideProjectCreator = const WritersideProjectCreator(),
    this.writersideTopicCreator = const WritersideTopicCreator(),
    this.scanOptions = const WorkspaceScanOptions(),
    Future<void> Function(String targetPath)? beforeNewFilePublish,
  }) : _beforeNewFilePublish = beforeNewFilePublish;

  final MarkdownParser markdownParser;
  final MarkdownPreviewBuilder previewBuilder;
  final WritersideModuleService writersideService;
  final WritersideProjectCreator writersideProjectCreator;
  final WritersideTopicCreator writersideTopicCreator;
  final WorkspaceScanOptions scanOptions;
  final Future<void> Function(String targetPath)? _beforeNewFilePublish;

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
      return _openWriterside(canonicalPath);
    }
    return _openMarkdownFolder(canonicalPath);
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
    WritersideTopicCreateRequest request,
  ) async {
    if (workspace.kind != WorkspaceKind.writersideModule ||
        workspace.writersideModule == null) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    final module = workspace.writersideModule!;
    if (module.instances.isEmpty) {
      throw const BusyMarkException('writerside.topic.instance-tree-missing');
    }
    final result = await writersideTopicCreator.create(
      WritersideTopicCreateTarget(
        rootPath: module.rootPath,
        treePath: module.instances.first.sourceTreePath,
        topicsRootDir: module.config.topicsDir,
        existingTopicIds: {for (final topic in module.topics) topic.id},
      ),
      request,
    );
    return _openWriterside(module.rootPath, activeFilePath: result.topicPath);
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
    return WorkspaceFileLoad(
      text: utf8.decode(bytes),
      snapshot: _snapshotFromBytes(stat, bytes),
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
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) async {
    final bytes = utf8.encode(text);
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
  ) async {
    final bytes = utf8.encode(text);
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

  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    final savePath = await _saveTargetPath(path);
    final target = File(savePath);
    final existingStat = await target.stat();
    final bytes = utf8.encode(text);
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
    final errorNumber = _LinuxNoReplaceApi.instance.publishNoReplace(
      stagedFile.absolute.path,
      File(targetPath).absolute.path,
    );
    if (errorNumber == null) {
      return;
    }
    if (errorNumber == _LinuxNoReplaceApi.fileExistsError) {
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
        final markdown = markdownParser.parse(
          filePath: active,
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          workspaceRoot: topic!.topicRoot,
          validateLocalReferences: false,
        );
        return workspace.copyWith(
          markdown: markdown,
          diagnostics: sortDiagnostics([
            ...module!.diagnostics,
            ...markdown.diagnostics,
          ]),
        );
      }
      if (topic?.format == WritersideTopicFormat.xml) {
        final parsed = writersideService.topicParser.parseXml(
          filePath: active,
          source: source,
          topicsRoot: topic!.topicRoot,
        );
        return workspace.copyWith(
          diagnostics: sortDiagnostics([
            ...module!.diagnostics,
            ...parsed.diagnostics,
          ]),
        );
      }
      return workspace.copyWith(diagnostics: module?.diagnostics);
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

  PreviewDocument? buildPreview(Workspace workspace, String source) {
    final active = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (active == null) {
      return null;
    }
    if (workspace.kind == WorkspaceKind.writersideModule) {
      final module = workspace.writersideModule;
      if (module == null) {
        return null;
      }
      final topic = module.topics
          .where((item) => item.filePath == active)
          .firstOrNull;
      if (topic == null) {
        return PreviewDocument(
          title: p.basename(active),
          modeLabel: '',
          compatibility: '',
          blocks: [PreviewBlock(kind: PreviewBlockKind.code, text: source)],
        );
      }
      if (topic.format == WritersideTopicFormat.markdown) {
        final parsed = markdownParser.parse(
          filePath: active,
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          workspaceRoot: topic.topicRoot,
          validateLocalReferences: false,
        );
        return previewBuilder.build(parsed);
      }
      return PreviewDocument(
        title: topic.title ?? topic.fileName,
        modeLabel: '',
        compatibility: '',
        blocks: _xmlPreviewBlocks(source, topic.title),
      );
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
    final scan = await scanWorkspaceEntities(rootPath, options: scanOptions);
    final entities = scan.entities;
    final files = <DocumentFile>[];
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
      diagnostics: sortDiagnostics(diagnostics),
      markdown: firstMarkdown,
    );
  }

  Future<Workspace> _openWriterside(
    String rootPath, {
    String? activeFilePath,
  }) async {
    final module = await writersideService.load(rootPath);
    final scan = await scanWorkspaceEntities(rootPath, options: scanOptions);
    final entities = scan.entities;
    final files = <DocumentFile>[];
    final diagnostics = <Diagnostic>[
      ...module.diagnostics,
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
    return Workspace(
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
      diagnostics: sortDiagnostics(diagnostics),
      writersideModule: module,
      markdown: module.topics
          .where((topic) => topic.filePath == firstTopic)
          .map((topic) => topic.markdown)
          .whereType<ParsedMarkdownDocument>()
          .firstOrNull,
    );
  }

  String? _startTopicPath(WritersideModule module) {
    if (module.instances.isEmpty) {
      return null;
    }
    final startPage = module.instances.first.startPage;
    if (startPage == null) {
      return null;
    }
    return module.topicByReference(startPage)?.filePath;
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
      return _documentFile(path, rootPath);
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
      return markdownParser.parseAsync(
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

  bool _visibleSemanticElement(String name) {
    return {
      'topic',
      'chapter',
      'p',
      'procedure',
      'step',
      'note',
      'tip',
      'warning',
      'tabs',
      'tab',
      'code-block',
      'img',
      'a',
    }.contains(name);
  }

  PreviewBlockKind _semanticKind(String name) {
    return switch (name) {
      'chapter' => PreviewBlockKind.heading,
      'procedure' => PreviewBlockKind.procedure,
      'note' || 'tip' || 'warning' => PreviewBlockKind.admonition,
      'tabs' || 'tab' => PreviewBlockKind.tabs,
      'code-block' => PreviewBlockKind.code,
      'img' => PreviewBlockKind.image,
      _ => PreviewBlockKind.paragraph,
    };
  }

  String _semanticText(String name, String? title) {
    return switch (name) {
      'topic' => title ?? '',
      'chapter' ||
      'procedure' ||
      'step' ||
      'note' ||
      'tip' ||
      'warning' ||
      'tabs' ||
      'tab' ||
      'code-block' ||
      'img' ||
      'a' => '',
      _ => name,
    };
  }

  List<PreviewBlock> _xmlPreviewBlocks(String source, String? title) {
    final names = RegExp(
      r'<\s*([A-Za-z][A-Za-z0-9_-]*)\b',
    ).allMatches(source).map((match) => match.group(1)!).toList();
    if (names.isEmpty) {
      return [PreviewBlock(kind: PreviewBlockKind.code, text: source)];
    }
    return [
      for (final name in names)
        if (_visibleSemanticElement(name))
          PreviewBlock(
            kind: _semanticKind(name),
            text: _semanticText(name, title),
            attributes: {'element': name},
          ),
    ];
  }
}

class _StagedSave {
  const _StagedSave({required this.directory, required this.file});

  final Directory directory;
  final File file;
}

typedef _RenameAt2Native =
    Int32 Function(
      Int32 oldDirectory,
      Pointer<Utf8> oldPath,
      Int32 newDirectory,
      Pointer<Utf8> newPath,
      Uint32 flags,
    );
typedef _RenameAt2Dart =
    int Function(
      int oldDirectory,
      Pointer<Utf8> oldPath,
      int newDirectory,
      Pointer<Utf8> newPath,
      int flags,
    );
typedef _ErrnoLocationNative = Pointer<Int32> Function();
typedef _ErrnoLocationDart = Pointer<Int32> Function();
typedef _LinkNative =
    Int32 Function(Pointer<Utf8> oldPath, Pointer<Utf8> newPath);
typedef _LinkDart = int Function(Pointer<Utf8> oldPath, Pointer<Utf8> newPath);

final class _LinuxNoReplaceApi {
  _LinuxNoReplaceApi() : _library = DynamicLibrary.open('libc.so.6') {
    try {
      _renameAt2 = _library.lookupFunction<_RenameAt2Native, _RenameAt2Dart>(
        'renameat2',
      );
    } on ArgumentError {
      _renameAt2 = null;
    }
    _link = _library.lookupFunction<_LinkNative, _LinkDart>('link');
    _errnoLocation = _library
        .lookupFunction<_ErrnoLocationNative, _ErrnoLocationDart>(
          '__errno_location',
        );
  }

  static const fileExistsError = 17;
  static const _invalidArgumentError = 22;
  static const _functionNotImplementedError = 38;
  static const _operationNotSupportedError = 95;
  static const _atCurrentWorkingDirectory = -100;
  static const _renameNoReplace = 1;
  static final instance = _LinuxNoReplaceApi();

  final DynamicLibrary _library;
  late final _RenameAt2Dart? _renameAt2;
  late final _LinkDart _link;
  late final _ErrnoLocationDart _errnoLocation;

  int? publishNoReplace(String oldPath, String newPath) {
    final nativeOldPath = oldPath.toNativeUtf8();
    final nativeNewPath = newPath.toNativeUtf8();
    try {
      final renameAt2 = _renameAt2;
      if (renameAt2 != null) {
        final result = renameAt2(
          _atCurrentWorkingDirectory,
          nativeOldPath,
          _atCurrentWorkingDirectory,
          nativeNewPath,
          _renameNoReplace,
        );
        if (result == 0) {
          return null;
        }
        final errorNumber = _errnoLocation().value;
        if (errorNumber != _invalidArgumentError &&
            errorNumber != _functionNotImplementedError &&
            errorNumber != _operationNotSupportedError) {
          return errorNumber;
        }
      }

      final linkResult = _link(nativeOldPath, nativeNewPath);
      return linkResult == 0 ? null : _errnoLocation().value;
    } finally {
      malloc.free(nativeOldPath);
      malloc.free(nativeNewPath);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
