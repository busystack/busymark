import '../core/diagnostic.dart';
import '../markdown/markdown_model.dart';
import '../markdown/preview_export.dart';
import '../writerside/writerside_model.dart';

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
  const Workspace({
    required this.id,
    required this.rootPath,
    required this.kind,
    required this.openedAt,
    required this.files,
    required this.diagnostics,
    this.activeFilePath,
    this.activeFileModifiedAt,
    this.markdown,
    this.writersideModule,
  });

  final String id;
  final String rootPath;
  final WorkspaceKind kind;
  final DateTime openedAt;
  final String? activeFilePath;
  final DateTime? activeFileModifiedAt;
  final List<DocumentFile> files;
  final List<Diagnostic> diagnostics;
  final ParsedMarkdownDocument? markdown;
  final WritersideModule? writersideModule;

  Workspace copyWith({
    String? activeFilePath,
    DateTime? activeFileModifiedAt,
    List<DocumentFile>? files,
    List<Diagnostic>? diagnostics,
    ParsedMarkdownDocument? markdown,
    WritersideModule? writersideModule,
  }) {
    return Workspace(
      id: id,
      rootPath: rootPath,
      kind: kind,
      openedAt: openedAt,
      activeFilePath: activeFilePath ?? this.activeFilePath,
      activeFileModifiedAt: activeFileModifiedAt ?? this.activeFileModifiedAt,
      files: files ?? this.files,
      diagnostics: diagnostics ?? this.diagnostics,
      markdown: markdown ?? this.markdown,
      writersideModule: writersideModule ?? this.writersideModule,
    );
  }
}

class WorkspaceState {
  const WorkspaceState({
    this.workspace,
    this.activeText = '',
    this.preview,
    this.isDirty = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final Workspace? workspace;
  final String activeText;
  final PreviewDocument? preview;
  final bool isDirty;
  final bool isLoading;
  final String? errorMessage;

  bool get hasUnsavedChanges => isDirty;

  WorkspaceState copyWith({
    Workspace? workspace,
    String? activeText,
    PreviewDocument? preview,
    bool? isDirty,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkspaceState(
      workspace: workspace ?? this.workspace,
      activeText: activeText ?? this.activeText,
      preview: preview ?? this.preview,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
