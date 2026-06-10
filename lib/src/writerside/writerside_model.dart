import '../core/diagnostic.dart';
import '../core/source_span.dart';
import '../markdown/markdown_model.dart';

class WritersideConfig {
  const WritersideConfig({
    required this.filePath,
    required this.moduleName,
    required this.topicsDir,
    required this.imagesDir,
    required this.snippetsDir,
    required this.resourcesDir,
    required this.apiSpecificationsDir,
    required this.buildConfigDir,
    required this.varsFile,
    required this.categoriesFile,
    required this.instanceSources,
    required this.diagnostics,
  });

  final String filePath;
  final String? moduleName;
  final String topicsDir;
  final String imagesDir;
  final String? snippetsDir;
  final String? resourcesDir;
  final String apiSpecificationsDir;
  final String buildConfigDir;
  final String? varsFile;
  final String? categoriesFile;
  final List<String> instanceSources;
  final List<Diagnostic> diagnostics;
}

class TocNode {
  const TocNode({
    required this.hidden,
    required this.children,
    required this.span,
    this.topicFileName,
    this.href,
    this.tocTitle,
    this.id,
  });

  final String? topicFileName;
  final String? href;
  final String? tocTitle;
  final String? id;
  final bool hidden;
  final List<TocNode> children;
  final SourceSpan span;

  Iterable<TocNode> flatten() sync* {
    yield this;
    for (final child in children) {
      yield* child.flatten();
    }
  }
}

class WritersideInstance {
  const WritersideInstance({
    required this.id,
    required this.name,
    required this.sourceTreePath,
    required this.startPage,
    required this.status,
    required this.isLibrary,
    required this.tocRoots,
    required this.diagnostics,
  });

  final String id;
  final String name;
  final String sourceTreePath;
  final String? startPage;
  final String status;
  final bool isLibrary;
  final List<TocNode> tocRoots;
  final List<Diagnostic> diagnostics;

  Set<String> get topicFileSet {
    return tocRoots
        .expand((node) => node.flatten())
        .map((node) => node.topicFileName)
        .whereType<String>()
        .toSet();
  }
}

enum WritersideTopicFormat { markdown, xml }

class WritersideElementId {
  const WritersideElementId({required this.id, required this.span});

  final String id;
  final SourceSpan span;
}

class WritersideInclude {
  const WritersideInclude({
    required this.from,
    required this.elementId,
    required this.nullable,
    required this.span,
  });

  final String? from;
  final String? elementId;
  final bool nullable;
  final SourceSpan span;
}

class WritersideTopic {
  const WritersideTopic({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.format,
    required this.title,
    required this.elementIds,
    required this.links,
    required this.images,
    required this.variables,
    required this.includes,
    required this.diagnostics,
    this.markdown,
    this.semanticElementNames = const [],
  });

  final String id;
  final String filePath;
  final String fileName;
  final WritersideTopicFormat format;
  final String? title;
  final List<WritersideElementId> elementIds;
  final List<MarkdownLink> links;
  final List<MarkdownImage> images;
  final List<MarkdownVariableToken> variables;
  final List<WritersideInclude> includes;
  final List<Diagnostic> diagnostics;
  final ParsedMarkdownDocument? markdown;
  final List<String> semanticElementNames;
}

class WritersideVariable {
  const WritersideVariable({
    required this.name,
    required this.value,
    required this.span,
  });

  final String name;
  final String value;
  final SourceSpan span;
}

class WritersideCategory {
  const WritersideCategory({
    required this.id,
    required this.name,
    required this.order,
    required this.span,
  });

  final String id;
  final String name;
  final int? order;
  final SourceSpan span;
}

class WritersideModule {
  const WritersideModule({
    required this.rootPath,
    required this.config,
    required this.instances,
    required this.topics,
    required this.variables,
    required this.categories,
    required this.diagnostics,
  });

  final String rootPath;
  final WritersideConfig config;
  final List<WritersideInstance> instances;
  final List<WritersideTopic> topics;
  final List<WritersideVariable> variables;
  final List<WritersideCategory> categories;
  final List<Diagnostic> diagnostics;

  Map<String, WritersideTopic> get topicsByFileName => {
    for (final topic in topics) topic.fileName: topic,
  };

  Map<String, WritersideTopic> get topicsById => {
    for (final topic in topics) topic.id: topic,
  };

  Set<String> get variableNames => {
    for (final variable in variables) variable.name,
    'instance',
    'instance-lowercase',
    'currentId',
    'thisTopic',
  };
}
