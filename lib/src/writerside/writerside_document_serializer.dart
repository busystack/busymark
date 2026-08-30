import 'writerside_document.dart';

/// Serializes an unmodified lossless document without normalizing unsupported
/// elements, attributes, comments, entities, or whitespace.
class WritersideDocumentSerializer {
  const WritersideDocumentSerializer();

  String serialize(WritersideDocument document) {
    if (document.format == WritersideDocumentFormat.markdown) {
      return document.source;
    }
    final serialized = document.nodes.map((node) => node.rawSource).join();
    return serialized.isEmpty ? document.source : serialized;
  }
}
