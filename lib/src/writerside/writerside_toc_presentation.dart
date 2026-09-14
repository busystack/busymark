import 'package:path/path.dart' as p;

import 'writerside_document_resolver.dart';
import 'writerside_model.dart';

/// Navigation text and status are independent of source/clipboard identity.
class WritersideTocPresentation {
  const WritersideTocPresentation({
    required this.label,
    required this.tooltip,
    required this.topic,
    required this.home,
    required this.empty,
    required this.included,
    required this.external,
    required this.unresolved,
    required this.hidden,
  });

  final String label;
  final String tooltip;
  final WritersideTopic? topic;
  final bool home;
  final bool empty;
  final bool included;
  final bool external;
  final bool unresolved;
  final bool hidden;
}

/// One cache per immutable module/instance snapshot. Uses the same conditional
/// and variable resolution as preview and export, including origin modules.
class WritersideTocPresenter {
  WritersideTocPresenter({
    required this.module,
    required this.instance,
    this.modulesByOrigin = const {},
  });

  final WritersideModule module;
  final WritersideInstance instance;
  final Map<String, WritersideModule> modulesByOrigin;
  final _titles = <WritersideTopic, String?>{};
  final _rows = <TocNode, WritersideTocPresentation>{};

  WritersideTocPresentation present(
    TocNode node,
  ) => _rows.putIfAbsent(node, () {
    final owner = node.origin == null ? module : modulesByOrigin[node.origin];
    final reference = node.topicReference;
    final topic = reference == null ? null : owner?.topicByReference(reference);
    final title = topic == null || owner == null
        ? null
        : _titles.putIfAbsent(
            topic,
            () => const WritersideDocumentResolver()
                .resolve(
                  topic.document,
                  WritersideResolveContext(
                    module: owner,
                    topic: topic,
                    instance: instance,
                    modulesByOrigin: modulesByOrigin,
                  ),
                )
                .title,
          );
    final unresolved = node.includeResolutionError != null;
    final external = node.href != null;
    final homeTopic = instance.startPage == null
        ? null
        : module.topicByReference(instance.startPage!);
    return WritersideTocPresentation(
      label: node.tocTitle == null
          ? title ?? reference ?? node.href ?? node.id ?? ''
          : const WritersideDocumentResolver().resolveNavigationTitle(
              node.tocTitle!,
              module: owner ?? module,
              instance: instance,
              topic: topic,
            ),
      tooltip: [
        if (external)
          node.href!
        else if (topic != null)
          topic.fileName
        else if (reference != null)
          reference,
        if (node.included)
          node.includeFrom ??
              p.basename(node.sourceTreePath ?? node.span.filePath),
        if (unresolved) node.includeResolutionError!,
      ].join('\n'),
      topic: topic,
      home:
          topic != null &&
          homeTopic != null &&
          p.equals(topic.filePath, homeTopic.filePath),
      empty: reference == null && !external && !unresolved && !node.included,
      included: node.included && !unresolved,
      external: external,
      unresolved: unresolved,
      hidden: node.hidden,
    );
  });
}
