import 'writerside_document.dart';

/// Preserves unmodified source byte-for-byte and structurally serializes only
/// semantic nodes that were changed through the document model.
class WritersideDocumentSerializer {
  const WritersideDocumentSerializer();

  String serialize(WritersideDocument document) {
    if (document.format == WritersideDocumentFormat.markdown) {
      return _serializeMarkdown(document);
    }
    final serialized = document.nodes.map(_serializeNode).join();
    return serialized.isEmpty ? document.source : serialized;
  }

  String _serializeMarkdown(WritersideDocument document) {
    final replacements = <({int start, int end, String value})>[];
    for (final node in document.nodes) {
      if (_hasModifications(node)) {
        replacements.add((
          start: node.span.startOffset,
          end: node.span.endOffset,
          value: _serializeNode(node),
        ));
      }
    }
    if (replacements.isEmpty) {
      return document.source;
    }
    replacements.sort((a, b) => b.start.compareTo(a.start));
    var result = document.source;
    for (final replacement in replacements) {
      result = result.replaceRange(
        replacement.start,
        replacement.end,
        replacement.value,
      );
    }
    return result;
  }

  bool _hasModifications(WritersideDocumentNode node) {
    if (node.isModified) {
      return true;
    }
    return node is WritersideElementNode &&
        node.children.any(_hasModifications);
  }

  String _serializeNode(WritersideDocumentNode node) {
    if (!_hasModifications(node)) {
      return node.rawSource;
    }
    return switch (node) {
      WritersideTextNode() => _escapeText(node.text),
      WritersideRawNode() => node.rawSource,
      WritersideMarkdownBlockNode() => node.rawSource,
      WritersideElementNode() => _serializeElement(node),
    };
  }

  String _serializeElement(WritersideElementNode element) {
    final attributes = element.attributes.entries
        .map((entry) => ' ${entry.key}="${_escapeAttribute(entry.value)}"')
        .join();
    if (element.children.isEmpty &&
        RegExp(r'/\s*>$').hasMatch(element.rawSource.trim())) {
      return '<${element.name}$attributes/>';
    }
    final children = element.children.map(_serializeNode).join();
    return '<${element.name}$attributes>$children</${element.name}>';
  }

  String _escapeText(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _escapeAttribute(String value) =>
      _escapeText(value).replaceAll('"', '&quot;');
}
