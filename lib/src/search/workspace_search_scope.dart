import '../workspace/workspace_model.dart';

/// The project text documents eligible for both search and replacement.
/// Opening a tab does not expand this scope.
bool isSearchableWorkspaceDocument(DocumentFile file) => switch (file.kind) {
  DocumentKind.markdown ||
  DocumentKind.writersideMarkdownTopic ||
  DocumentKind.writersideXmlTopic ||
  DocumentKind.tree ||
  DocumentKind.config ||
  DocumentKind.variables ||
  DocumentKind.categories ||
  DocumentKind.gitIgnore ||
  DocumentKind.resource => true,
  DocumentKind.image || DocumentKind.unknown => false,
};
