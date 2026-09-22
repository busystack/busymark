import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../markdown/document_outline.dart';
import '../markdown/markdown_model.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_model.dart';
import '../writerside/writerside_project.dart';
import 'document_buffer.dart';
import 'workspace_message.dart';
import 'workspace_file_snapshot.dart';

export 'workspace_file_snapshot.dart';

const Object _copyWithUnset = _CopyWithUnset();

class _CopyWithUnset {
  const _CopyWithUnset();
}

enum WorkspaceKind {
  untitledMarkdown,
  singleMarkdown,
  markdownFolder,
  writersideModule,
}

enum DocumentKind {
  markdown,
  writersideMarkdownTopic,
  writersideXmlTopic,
  tree,
  config,
  variables,
  categories,
  gitIgnore,
  image,
  resource,
  unknown,
}

extension DocumentKindAiSupport on DocumentKind {
  bool get supportsAiMarkdownEditing =>
      this == DocumentKind.markdown ||
      this == DocumentKind.writersideMarkdownTopic;
}

extension DocumentKindSpellingSupport on DocumentKind {
  bool get supportsSpelling =>
      this == DocumentKind.markdown ||
      this == DocumentKind.writersideMarkdownTopic ||
      this == DocumentKind.writersideXmlTopic;
}

class ActiveDocumentOutline {
  const ActiveDocumentOutline({
    required this.workspaceId,
    required this.bufferId,
    required this.filePath,
    required this.source,
    required this.headings,
  });

  final String workspaceId;
  final String bufferId;
  final String? filePath;
  final String source;
  final List<DocumentOutlineHeading> headings;

  bool matches(
    Workspace workspace,
    DocumentBuffer? activeBuffer,
    String activeSource,
  ) {
    return workspaceId == workspace.id &&
        activeBuffer != null &&
        bufferId == activeBuffer.id &&
        filePath == activeBuffer.filePath &&
        source == activeSource;
  }
}

/// Derived routing information for one editor buffer in its workspace.
///
/// A workspace describes the open project/container. This context describes
/// the actual document being edited and must therefore always be resolved from
/// a concrete [DocumentBuffer].
class WorkspaceDocumentContext {
  const WorkspaceDocumentContext({
    required this.kind,
    required this.markdownMode,
    required this.diskPath,
    required this.parserPath,
    this.writersideModule,
    this.writersideTopic,
  });

  final DocumentKind kind;
  final MarkdownMode markdownMode;
  final String? diskPath;
  final String parserPath;
  final WritersideModule? writersideModule;
  final WritersideTopic? writersideTopic;

  bool get isWritersideOwned =>
      writersideTopic != null ||
      (diskPath != null &&
          writersideModule != null &&
          kind != DocumentKind.markdown &&
          kind != DocumentKind.unknown &&
          kind != DocumentKind.image &&
          kind != DocumentKind.gitIgnore);
}

/// Resolves the effective document type independently of [Workspace.kind].
WorkspaceDocumentContext resolveWorkspaceDocumentContext(
  Workspace workspace,
  DocumentBuffer buffer,
) {
  final path = buffer.filePath;
  if (path == null) {
    return const WorkspaceDocumentContext(
      kind: DocumentKind.markdown,
      markdownMode: MarkdownMode.commonMark,
      diskPath: null,
      parserPath: '',
    );
  }

  final normalizedPath = normalizePath(path);
  final projectModules = workspace.writersideProject?.modules;
  final modules = <WritersideModule>[
    if (projectModules != null) ...projectModules,
    if (projectModules == null)
      if (workspace.writersideModule case final module?) module,
  ];
  for (final module in modules) {
    for (final topic in module.topics) {
      if (!p.equals(normalizePath(topic.filePath), normalizedPath)) continue;
      return WorkspaceDocumentContext(
        kind: topic.format == WritersideTopicFormat.markdown
            ? DocumentKind.writersideMarkdownTopic
            : DocumentKind.writersideXmlTopic,
        markdownMode: topic.format == WritersideTopicFormat.markdown
            ? MarkdownMode.writersideMarkdown
            : MarkdownMode.commonMark,
        diskPath: path,
        parserPath: path,
        writersideModule: module,
        writersideTopic: topic,
      );
    }
  }

  final inventoryKind = workspace.files
      .where(
        (file) => p.equals(normalizePath(file.absolutePath), normalizedPath),
      )
      .map((file) => file.kind)
      .firstOrNull;
  final kind = inventoryKind ?? documentKindForPath(path);
  final owningModule = modules
      .where((module) => _isWritersideOwnedFile(module, normalizedPath))
      .firstOrNull;
  return WorkspaceDocumentContext(
    kind: kind,
    markdownMode: MarkdownMode.commonMark,
    diskPath: path,
    parserPath: path,
    writersideModule: owningModule,
  );
}

/// Existing path/name classification shared by scanning and document routing.
DocumentKind documentKindForPath(String path) {
  final extension = p.extension(path).toLowerCase();
  final basename = p.basename(path);
  if (basename == '.gitignore') return DocumentKind.gitIgnore;
  if (extension == '.md' || extension == '.markdown') {
    return DocumentKind.markdown;
  }
  if (extension == '.topic') return DocumentKind.writersideXmlTopic;
  if (extension == '.tree') return DocumentKind.tree;
  if (extension == '.cfg' ||
      basename == 'writerside.cfg' ||
      basename == 'project.ihp') {
    return DocumentKind.config;
  }
  if (basename == 'v.list') return DocumentKind.variables;
  if (basename == 'c.list') return DocumentKind.categories;
  if ({'.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'}.contains(extension)) {
    return DocumentKind.image;
  }
  return isTextDocumentationPath(path)
      ? DocumentKind.resource
      : DocumentKind.unknown;
}

bool _isWritersideOwnedFile(WritersideModule module, String path) {
  final config = module.config;
  final configured = <String>{
    config.filePath,
    for (final source in module.sourceFiles.values)
      if (source.path case final sourcePath?) sourcePath,
    for (final source in module.referenceData.sources.values)
      if (source.path case final sourcePath?) sourcePath,
    for (final instance in module.instances) instance.sourceTreePath,
    for (final instance in config.instances)
      _writersideConfiguredPath(module.rootPath, instance.src),
    if (config.varsFile case final configuredPath?)
      _writersideConfiguredPath(module.rootPath, configuredPath),
    if (config.categoriesFile case final configuredPath?)
      _writersideConfiguredPath(module.rootPath, configuredPath),
    if (config.instanceGroupsFile case final configuredPath?)
      _writersideConfiguredPath(module.rootPath, configuredPath),
    _writersideConfiguredPath(
      module.rootPath,
      p.join(config.buildConfigDir, 'buildprofiles.xml'),
    ),
  };
  return configured.any(
    (candidate) => p.equals(normalizePath(candidate), path),
  );
}

String _writersideConfiguredPath(String rootPath, String configuredPath) {
  return normalizePath(
    p.isAbsolute(configuredPath)
        ? configuredPath
        : p.join(rootPath, configuredPath),
  );
}

class DocumentFile {
  const DocumentFile({
    required this.absolutePath,
    required this.relativePath,
    required this.kind,
    required this.size,
    required this.lastModified,
  });

  final String absolutePath;
  final String relativePath;
  final DocumentKind kind;
  final int size;
  final DateTime lastModified;
}

class WorkspaceDirectory {
  const WorkspaceDirectory({
    required this.absolutePath,
    required this.relativePath,
  });

  final String absolutePath;
  final String relativePath;
}

class Workspace {
  Workspace({
    required this.id,
    required this.rootPath,
    required this.kind,
    required this.openedAt,
    required this.files,
    required this.diagnostics,
    this.runtimeDiagnostics = const [],
    this.sourceOverrides = const {},
    this.directories = const [],
    List<String> openFilePaths = const [],
    this.activeFilePath,
    DateTime? activeFileModifiedAt,
    this.activeFileSnapshot,
    this.markdown,
    this.writersideModule,
    this.writersideProject,
  }) : openFilePaths = _normalizedOpenFilePaths(openFilePaths, activeFilePath),
       activeFileModifiedAt =
           activeFileModifiedAt ?? activeFileSnapshot?.modifiedAt;

  final String id;
  final String rootPath;
  final WorkspaceKind kind;
  final DateTime openedAt;
  final String? activeFilePath;
  final DateTime? activeFileModifiedAt;
  final WorkspaceFileSnapshot? activeFileSnapshot;
  final List<String> openFilePaths;
  final List<DocumentFile> files;
  final List<WorkspaceDirectory> directories;
  final List<Diagnostic> diagnostics;
  final List<Diagnostic> runtimeDiagnostics;

  /// Current editor sources for a single validation snapshot.
  final Map<String, String> sourceOverrides;
  List<Diagnostic> get allDiagnostics =>
      sortDiagnostics([...diagnostics, ...runtimeDiagnostics]);
  final ParsedMarkdownDocument? markdown;
  final WritersideModule? writersideModule;
  final WritersideProject? writersideProject;

  Workspace copyWith({
    Object? activeFilePath = _copyWithUnset,
    Object? activeFileModifiedAt = _copyWithUnset,
    Object? activeFileSnapshot = _copyWithUnset,
    List<String>? openFilePaths,
    List<DocumentFile>? files,
    List<WorkspaceDirectory>? directories,
    List<Diagnostic>? diagnostics,
    List<Diagnostic>? runtimeDiagnostics,
    Map<String, String>? sourceOverrides,
    Object? markdown = _copyWithUnset,
    Object? writersideModule = _copyWithUnset,
    Object? writersideProject = _copyWithUnset,
  }) {
    final nextActiveFilePath = identical(activeFilePath, _copyWithUnset)
        ? this.activeFilePath
        : activeFilePath as String?;
    final nextSnapshot = identical(activeFileSnapshot, _copyWithUnset)
        ? this.activeFileSnapshot
        : activeFileSnapshot as WorkspaceFileSnapshot?;
    final nextModifiedAt = identical(activeFileModifiedAt, _copyWithUnset)
        ? identical(activeFileSnapshot, _copyWithUnset)
              ? this.activeFileModifiedAt
              : nextSnapshot?.modifiedAt
        : activeFileModifiedAt as DateTime?;
    final nextMarkdown = identical(markdown, _copyWithUnset)
        ? this.markdown
        : markdown as ParsedMarkdownDocument?;
    final nextWritersideModule = identical(writersideModule, _copyWithUnset)
        ? this.writersideModule
        : writersideModule as WritersideModule?;
    final nextWritersideProject = identical(writersideProject, _copyWithUnset)
        ? this.writersideProject
        : writersideProject as WritersideProject?;
    return Workspace(
      id: id,
      rootPath: rootPath,
      kind: kind,
      openedAt: openedAt,
      activeFilePath: nextActiveFilePath,
      activeFileModifiedAt: nextModifiedAt,
      activeFileSnapshot: nextSnapshot,
      openFilePaths: openFilePaths ?? this.openFilePaths,
      files: files ?? this.files,
      directories: directories ?? this.directories,
      diagnostics: diagnostics ?? this.diagnostics,
      runtimeDiagnostics: runtimeDiagnostics ?? this.runtimeDiagnostics,
      sourceOverrides: sourceOverrides ?? this.sourceOverrides,
      markdown: nextMarkdown,
      writersideModule: nextWritersideModule,
      writersideProject: nextWritersideProject,
    );
  }
}

/// Whether [path] is part of the currently discovered Writerside project.
/// Module roots cover newly opened project files, while the explicit source
/// inventory also handles any configured source whose canonical path is known.
bool isWritersideProjectPath(Workspace workspace, String path) {
  final project = workspace.writersideProject;
  if (project == null || path.isEmpty) return false;
  final candidate = normalizePath(path);
  for (final module in project.modules) {
    final root = normalizePath(module.rootPath);
    if (p.equals(candidate, root) || p.isWithin(root, candidate)) return true;
    final knownPaths = <String>{
      module.config.filePath,
      for (final instance in module.instances) instance.sourceTreePath,
      for (final topic in module.topics) topic.filePath,
      ...module.sourceFiles.keys,
    };
    if (knownPaths.any((known) => p.equals(candidate, known))) return true;
  }
  return false;
}

List<String> _normalizedOpenFilePaths(
  List<String> openFilePaths,
  String? activeFilePath,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final path in openFilePaths) {
    if (path.isEmpty || !seen.add(path)) {
      continue;
    }
    result.add(path);
  }
  if (activeFilePath != null &&
      activeFilePath.isNotEmpty &&
      seen.add(activeFilePath)) {
    result.add(activeFilePath);
  }
  return List.unmodifiable(result);
}

class WorkspaceState {
  const WorkspaceState({
    this.workspace,
    String activeText = '',
    this.preview,
    this.liveOutline,
    bool isDirty = false,
    this.documentBuffers = const [],
    this.activeBufferId,
    this.isLoading = false,
    this.message,
  }) : _legacyActiveText = activeText,
       _legacyIsDirty = isDirty;

  final Workspace? workspace;
  final String _legacyActiveText;
  final PreviewDocument? preview;
  final ActiveDocumentOutline? liveOutline;
  final bool _legacyIsDirty;
  final List<DocumentBuffer> documentBuffers;
  final String? activeBufferId;
  final bool isLoading;
  final WorkspaceMessage? message;

  DocumentBuffer? get activeBuffer {
    final id = activeBufferId;
    if (id == null) {
      return null;
    }
    for (final buffer in documentBuffers) {
      if (buffer.id == id) {
        return buffer;
      }
    }
    return null;
  }

  String get activeText => activeBuffer?.text ?? _legacyActiveText;

  bool get isDirty => activeBuffer?.isDirty ?? _legacyIsDirty;

  bool get hasUnsavedChanges => documentBuffers.isEmpty
      ? _legacyIsDirty
      : documentBuffers.any((buffer) => buffer.isDirty);

  List<DocumentBuffer> get dirtyBuffers =>
      List.unmodifiable(documentBuffers.where((buffer) => buffer.isDirty));

  DocumentBuffer? bufferForPath(String path) {
    for (final buffer in documentBuffers) {
      if (buffer.filePath == path) {
        return buffer;
      }
    }
    return null;
  }

  WorkspaceState copyWith({
    Workspace? workspace,
    String? activeText,
    Object? preview = _copyWithUnset,
    Object? liveOutline = _copyWithUnset,
    bool? isDirty,
    List<DocumentBuffer>? documentBuffers,
    Object? activeBufferId = _copyWithUnset,
    bool? isLoading,
    WorkspaceMessage? message,
    bool clearMessage = false,
  }) {
    final replacesPreview = !identical(preview, _copyWithUnset);
    final nextPreview = !replacesPreview
        ? this.preview
        : preview as PreviewDocument?;
    final nextLiveOutline = !identical(liveOutline, _copyWithUnset)
        ? liveOutline as ActiveDocumentOutline?
        : replacesPreview
        ? null
        : this.liveOutline;
    return WorkspaceState(
      workspace: workspace ?? this.workspace,
      activeText: activeText ?? _legacyActiveText,
      preview: nextPreview,
      liveOutline: nextLiveOutline,
      isDirty: isDirty ?? _legacyIsDirty,
      documentBuffers: documentBuffers ?? this.documentBuffers,
      activeBufferId: identical(activeBufferId, _copyWithUnset)
          ? this.activeBufferId
          : activeBufferId as String?,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
