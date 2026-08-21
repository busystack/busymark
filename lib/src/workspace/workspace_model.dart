import '../core/diagnostic.dart';
import '../markdown/document_outline.dart';
import '../markdown/markdown_model.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_model.dart';
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

class ActiveDocumentOutline {
  const ActiveDocumentOutline({
    required this.workspaceId,
    required this.filePath,
    required this.source,
    required this.headings,
  });

  final String workspaceId;
  final String? filePath;
  final String source;
  final List<DocumentOutlineHeading> headings;

  bool matches(Workspace workspace, String activeSource) {
    return workspaceId == workspace.id &&
        filePath == workspace.activeFilePath &&
        source == activeSource;
  }
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
    this.directories = const [],
    List<String> openFilePaths = const [],
    this.activeFilePath,
    DateTime? activeFileModifiedAt,
    this.activeFileSnapshot,
    this.markdown,
    this.writersideModule,
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
  final ParsedMarkdownDocument? markdown;
  final WritersideModule? writersideModule;

  Workspace copyWith({
    Object? activeFilePath = _copyWithUnset,
    Object? activeFileModifiedAt = _copyWithUnset,
    Object? activeFileSnapshot = _copyWithUnset,
    List<String>? openFilePaths,
    List<DocumentFile>? files,
    List<WorkspaceDirectory>? directories,
    List<Diagnostic>? diagnostics,
    Object? markdown = _copyWithUnset,
    Object? writersideModule = _copyWithUnset,
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
      markdown: nextMarkdown,
      writersideModule: nextWritersideModule,
    );
  }
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
