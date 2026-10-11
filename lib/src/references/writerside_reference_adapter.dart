import '../writerside/writerside_document_resolver.dart';
import '../writerside/writerside_project.dart';
import '../writerside/writerside_document.dart';
import '../writerside/writerside_schema.dart';
import 'reference_index.dart';
import 'markdown_references.dart';

// Adapts the established Writerside symbol index; there is no second parser.
void addWritersideReferences(
  ReferenceIndex index,
  WritersideProjectIndex writerside,
  String? instanceId,
) {
  final documents = index.documents,
      targets = index.targets,
      references = index.references;
  final origins = writerside.modulesById;
  String symbolLabel(WritersideSymbol symbol) {
    final node = origins[symbol.moduleId]?.topics
        .where((t) => t.filePath == symbol.filePath)
        .firstOrNull
        ?.document
        .contentById(symbol.name)
        ?.firstOrNull;
    if (node is WritersideMarkdownBlockNode) return node.block.plainText;
    if (node is WritersideElementNode) {
      return node.attributes['title'] ?? symbol.name;
    }
    return symbol.name;
  }

  for (final symbol in writerside.symbols.where(
    (s) => {
      WritersideSymbolKind.topic,
      WritersideSymbolKind.element,
      WritersideSymbolKind.snippet,
    }.contains(s.kind),
  )) {
    final document = documents[symbol.filePath];
    if (document == null) continue;
    final anchor = symbol.kind == WritersideSymbolKind.topic
        ? null
        : symbol.name;
    if (anchor == null) {
      targets.removeWhere(
        (t) =>
            t.document.identity == document.identity &&
            t.anchor == null &&
            t.moduleId == null,
      );
    }
    if (!targets.any(
      (t) => t.document.identity == document.identity && t.anchor == anchor,
    )) {
      targets.add(
        ReferenceTarget(
          document,
          anchor: anchor,
          label: symbolLabel(symbol),
          span: symbol.span,
          moduleId: symbol.moduleId,
          scopeSpan: writerside.modulesById[symbol.moduleId]?.topics
              .where((t) => t.filePath == symbol.filePath)
              .firstOrNull
              ?.document
              .contentById(symbol.name)
              ?.firstOrNull
              ?.span,
        ),
      );
    }
  }
  for (final ref in writerside.references.where(
    (r) => {
      WritersideSymbolKind.topic,
      WritersideSymbolKind.element,
      WritersideSymbolKind.snippet,
    }.contains(r.kind),
  )) {
    final document = documents[ref.filePath];
    if (document == null) continue;
    final sourceModule = origins[ref.moduleId];
    final sourceTopic = sourceModule?.topics
        .where((t) => t.filePath == ref.filePath)
        .firstOrNull;
    final sourceInstance = sourceModule?.instances
        .where((i) => i.id == instanceId)
        .firstOrNull;
    final sourceNode = sourceTopic?.document
        .walk()
        .where(
          (n) =>
              n.span.startOffset <= ref.span.startOffset &&
              n.span.endOffset >= ref.span.endOffset,
        )
        .lastOrNull;
    Map<String, String>? dynamicLink;
    if (ref.value.contains('%') &&
        sourceModule != null &&
        sourceTopic != null &&
        sourceNode != null &&
        sourceNode is WritersideElementNode &&
        sourceNode.semanticKind == WritersideSemanticKind.link) {
      dynamicLink = const WritersideDocumentResolver().resolveAuthoredLink(
        context: WritersideResolveContext(
          module: sourceModule,
          topic: sourceTopic,
          instance: sourceInstance,
          modulesByOrigin: origins,
        ),
        node: sourceNode,
        destination: ref.value,
        origin: ref.origin,
      );
    }
    final definitions = writerside.definitions(
      dynamicLink?['resolved-destination'] ?? ref.value,
      moduleId: ref.moduleId,
      origin: ref.origin,
      kind: ref.kind,
      filePath: ref.filePath,
      referenceOffset: ref.span.startOffset,
      scopeReference: ref.scopeReference,
    );
    final unique = <String, WritersideSymbol>{
      for (final symbol in definitions)
        '${symbol.filePath}:${symbol.kind == WritersideSymbolKind.topic ? '' : '${symbol.name}:${symbol.span?.startOffset}'}':
            symbol,
    };
    var resolution = unique.isEmpty
        ? ReferenceResolution.missing
        : unique.length > 1
        ? ReferenceResolution.ambiguous
        : ReferenceResolution.resolved;
    if (unique.isEmpty &&
        writerside.modulesById[ref.origin ?? ref.moduleId]
                ?.isUnparsedTopicReference(ref.value.split('#').first) ==
            true) {
      resolution = ReferenceResolution.unavailable;
    }
    ReferenceTarget? target;
    var includeReference = ref.kind == WritersideSymbolKind.snippet;
    if (unique.length == 1) {
      final symbol = unique.values.single;
      final targetDocument = documents[symbol.filePath];
      if (targetDocument != null) {
        target = ReferenceTarget(
          targetDocument,
          anchor: symbol.kind == WritersideSymbolKind.topic
              ? null
              : symbol.name,
          label: symbolLabel(symbol),
          span: symbol.span,
          moduleId: symbol.moduleId,
          scopeSpan: origins[symbol.moduleId]?.topics
              .where((t) => t.filePath == symbol.filePath)
              .firstOrNull
              ?.document
              .contentById(symbol.name)
              ?.firstOrNull
              ?.span,
        );
      }
      final module = origins[ref.moduleId];
      final topic = module?.topics
          .where((t) => t.filePath == ref.filePath)
          .firstOrNull;
      final instance = module?.instances
          .where((i) => i.id == instanceId)
          .firstOrNull;
      final node = topic?.document
          .walk()
          .where(
            (n) =>
                n.span.startOffset <= ref.span.startOffset &&
                n.span.endOffset >= ref.span.endOffset,
          )
          .lastOrNull;
      if (module != null && topic != null && node != null) {
        includeReference =
            node is WritersideElementNode &&
            node.semanticKind == WritersideSemanticKind.include;
        final available = includeReference
            ? const WritersideDocumentResolver().authoredIncludeAvailable(
                context: WritersideResolveContext(
                  module: module,
                  topic: topic,
                  instance: instance,
                  modulesByOrigin: origins,
                ),
                include: node,
              )
            : (dynamicLink ??
                      const WritersideDocumentResolver().resolveAuthoredLink(
                        context: WritersideResolveContext(
                          module: module,
                          topic: topic,
                          instance: instance,
                          modulesByOrigin: origins,
                        ),
                        node: node,
                        destination: ref.value,
                        origin: ref.origin,
                      ))['resolved-available'] ==
                  'true';
        if (!available) resolution = ReferenceResolution.unavailable;
      }
    }
    references.add(
      IndexedReference(
        source: document,
        authored: AuthoredReference(
          destination: ref.value,
          kind: includeReference
              ? AuthoredReferenceKind.include
              : AuthoredReferenceKind.topic,
          occurrence: ref.span,
          destinationSpan: ref.span,
          label: ref.sourceValue ?? ref.value,
          origin: ref.origin,
          moduleId: ref.moduleId,
        ),
        resolution: resolution,
        target: target,
      ),
    );
  }
  index.rebuildLookups();
}
