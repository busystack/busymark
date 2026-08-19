import '../core/diagnostic.dart';
import '../markdown/document_outline.dart';
import '../markdown/markdown_model.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_model.dart';
import 'workspace_message.dart';

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

class WorkspaceFileSnapshot {
  const WorkspaceFileSnapshot({
    required this.modifiedAt,
    required this.size,
    required this.contentHash,
  });

  final DateTime modifiedAt;
  final int size;
  final String contentHash;

  bool differsFrom(WorkspaceFileSnapshot other) {
    // A timestamp-only change cannot lose user content. Prefer the hashes when
    // both snapshots have one so metadata touches and filesystem timestamp
    // rounding do not produce false external-edit conflicts.
    if (contentHash.isNotEmpty && other.contentHash.isNotEmpty) {
      return contentHash != other.contentHash;
    }
    return modifiedAt != other.modifiedAt || size != other.size;
  }
}

class WorkspaceFileLoad {
  const WorkspaceFileLoad({required this.text, required this.snapshot});

  final String text;
  final WorkspaceFileSnapshot snapshot;
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

class Workspace {
  Workspace({
    required this.id,
    required this.rootPath,
    required this.kind,
    required this.openedAt,
    required this.files,
    required this.diagnostics,
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
  final List<Diagnostic> diagnostics;
  final ParsedMarkdownDocument? markdown;
  final WritersideModule? writersideModule;

  Workspace copyWith({
    Object? activeFilePath = _copyWithUnset,
    Object? activeFileModifiedAt = _copyWithUnset,
    Object? activeFileSnapshot = _copyWithUnset,
    List<String>? openFilePaths,
    List<DocumentFile>? files,
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
    this.activeText = '',
    this.preview,
    this.liveOutline,
    this.isDirty = false,
    this.isLoading = false,
    this.message,
  });

  final Workspace? workspace;
  final String activeText;
  final PreviewDocument? preview;
  final ActiveDocumentOutline? liveOutline;
  final bool isDirty;
  final bool isLoading;
  final WorkspaceMessage? message;

  bool get hasUnsavedChanges => isDirty;

  WorkspaceState copyWith({
    Workspace? workspace,
    String? activeText,
    Object? preview = _copyWithUnset,
    Object? liveOutline = _copyWithUnset,
    bool? isDirty,
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
      activeText: activeText ?? this.activeText,
      preview: nextPreview,
      liveOutline: nextLiveOutline,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
