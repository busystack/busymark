import '../core/diagnostic.dart';
import '../markdown/markdown_model.dart';
import '../markdown/preview_model.dart';
import '../writerside/writerside_model.dart';
import 'workspace_message.dart';

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
    return modifiedAt != other.modifiedAt ||
        size != other.size ||
        contentHash != other.contentHash;
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
    this.activeFilePath,
    DateTime? activeFileModifiedAt,
    this.activeFileSnapshot,
    this.markdown,
    this.writersideModule,
  }) : activeFileModifiedAt =
           activeFileModifiedAt ?? activeFileSnapshot?.modifiedAt;

  final String id;
  final String rootPath;
  final WorkspaceKind kind;
  final DateTime openedAt;
  final String? activeFilePath;
  final DateTime? activeFileModifiedAt;
  final WorkspaceFileSnapshot? activeFileSnapshot;
  final List<DocumentFile> files;
  final List<Diagnostic> diagnostics;
  final ParsedMarkdownDocument? markdown;
  final WritersideModule? writersideModule;

  Workspace copyWith({
    String? activeFilePath,
    DateTime? activeFileModifiedAt,
    WorkspaceFileSnapshot? activeFileSnapshot,
    List<DocumentFile>? files,
    List<Diagnostic>? diagnostics,
    ParsedMarkdownDocument? markdown,
    WritersideModule? writersideModule,
  }) {
    final nextSnapshot = activeFileSnapshot ?? this.activeFileSnapshot;
    return Workspace(
      id: id,
      rootPath: rootPath,
      kind: kind,
      openedAt: openedAt,
      activeFilePath: activeFilePath ?? this.activeFilePath,
      activeFileModifiedAt:
          activeFileModifiedAt ??
          nextSnapshot?.modifiedAt ??
          this.activeFileModifiedAt,
      activeFileSnapshot: nextSnapshot,
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
    this.message,
  });

  final Workspace? workspace;
  final String activeText;
  final PreviewDocument? preview;
  final bool isDirty;
  final bool isLoading;
  final WorkspaceMessage? message;

  bool get hasUnsavedChanges => isDirty;

  WorkspaceState copyWith({
    Workspace? workspace,
    String? activeText,
    PreviewDocument? preview,
    bool? isDirty,
    bool? isLoading,
    WorkspaceMessage? message,
    bool clearMessage = false,
  }) {
    return WorkspaceState(
      workspace: workspace ?? this.workspace,
      activeText: activeText ?? this.activeText,
      preview: preview ?? this.preview,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
