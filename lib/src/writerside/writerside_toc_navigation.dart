import 'package:xml/xml.dart';

import '../core/source_span.dart';
import 'writerside_document.dart';
import 'writerside_document_parser.dart';
import 'writerside_model.dart';
import 'writerside_topic_creator.dart';

/// Installed 2026.07.8925 uses PLAIN_BFS.first, not depth-first traversal,
/// when explicitly synchronizing the current instance with a topic editor.
List<int>? writersideTocBreadthFirstPath(
  List<TocNode> roots,
  bool Function(TocNode) matches,
) {
  final queue = <({TocNode node, List<int> path})>[
    for (var i = 0; i < roots.length; i++) (node: roots[i], path: [i]),
  ];
  for (var index = 0; index < queue.length; index++) {
    final item = queue[index];
    if (matches(item.node)) return item.path;
    for (var child = 0; child < item.node.children.length; child++) {
      queue.add((node: item.node.children[child], path: [...item.path, child]));
    }
  }
  return null;
}

/// The installed tree-editor synchronization action reads the nearest XML
/// tag's explicit id and passes it to the current tree's topic-key matcher.
/// An element without an id does not initiate synchronization in that build.
String? writersideTocEditorSyncKey(String filePath, String source, int offset) {
  final document = const WritersideDocumentParser().parseXml(
    filePath: filePath,
    source: source,
  );
  if (!document.isWellFormed) return null;
  WritersideElementNode? nearest;
  for (final element in document.elements) {
    if (element.span.startOffset <= offset &&
        offset < element.span.endOffset &&
        (nearest == null ||
            element.span.endOffset - element.span.startOffset <
                nearest.span.endOffset - nearest.span.startOffset)) {
      nearest = element;
    }
  }
  return nearest?.name == 'toc-element' ? nearest?.attributes['id'] : null;
}

/// Re-resolves an exact authored element against the buffer being revealed.
/// A changed identity is rejected instead of navigating to a different node.
SourceSpan? writersideTocSourceSpan({
  required String filePath,
  required String source,
  required List<int> path,
  required WritersideTocNodeIdentity identity,
  bool xmlChildren = false,
}) {
  if (path.isEmpty) return null;
  final document = const WritersideDocumentParser().parseXml(
    filePath: filePath,
    source: source,
  );
  if (!document.isWellFormed ||
      document.rootElement?.name != 'instance-profile') {
    return null;
  }
  List<WritersideElementNode> tocChildren(WritersideElementNode node) => node
      .children
      .whereType<WritersideElementNode>()
      .where((child) => xmlChildren || child.name == 'toc-element')
      .toList();
  var children = tocChildren(document.rootElement!);
  for (var depth = 0; depth < path.length; depth++) {
    final index = path[depth];
    if (index < 0 || index >= children.length) return null;
    final node = children[index];
    if (depth == path.length - 1) {
      try {
        final element = XmlDocument.parse(
          source.substring(node.span.startOffset, node.span.endOffset),
        ).rootElement;
        return identity.matches(element) ? node.span : null;
      } on XmlParserException {
        return null;
      }
    }
    children = tocChildren(node);
  }
  return null;
}
