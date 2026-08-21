import '../core/diagnostic.dart';
import '../core/source_span.dart';
import '../markdown/markdown_model.dart';
import 'package:path/path.dart' as p;

class WritersideTopicRoot {
  const WritersideTopicRoot({required this.dir, required this.explicit});

  final String dir;
  final bool explicit;
}

class WritersideImageRoot {
  const WritersideImageRoot({
    required this.dir,
    required this.explicit,
    this.version,
    this.webPath,
  });

  final String dir;
  final bool explicit;
  final String? version;
  final String? webPath;
}

class WritersideConfiguredInstance {
  const WritersideConfiguredInstance({
    required this.src,
    this.version,
    this.webPath,
    this.keymapsMode,
  });

  final String src;
  final String? version;
  final String? webPath;
  final String? keymapsMode;
}

class WritersideBuildProfileValues {
  const WritersideBuildProfileValues({this.noindexContent, this.offlineDocs});

  final bool? noindexContent;
  final bool? offlineDocs;

  bool get isEmpty => noindexContent == null && offlineDocs == null;
}

class WritersideBuildProfilesConfig {
  const WritersideBuildProfilesConfig({
    required this.filePath,
    this.globalValues = const WritersideBuildProfileValues(),
    this.instanceValues = const {},
    this.diagnostics = const [],
  });

  final String filePath;
  final WritersideBuildProfileValues globalValues;
  final Map<String, WritersideBuildProfileValues> instanceValues;
  final List<Diagnostic> diagnostics;

  WritersideBuildProfileValues valuesFor(String instanceId) {
    return instanceValues[instanceId] ?? const WritersideBuildProfileValues();
  }

  bool allowsSearchEngineIndexing(String instanceId) {
    final specific = valuesFor(instanceId).noindexContent;
    final noindex = specific ?? globalValues.noindexContent ?? true;
    return !noindex;
  }

  bool createsOfflineArtifact(String instanceId) {
    return valuesFor(instanceId).offlineDocs ??
        globalValues.offlineDocs ??
        false;
  }
}

class WritersideInstanceGroup {
  const WritersideInstanceGroup({
    required this.id,
    required this.instanceIds,
    required this.span,
  });

  final String id;
  final Set<String> instanceIds;
  final SourceSpan span;
}

class WritersideInstanceGroupsConfig {
  const WritersideInstanceGroupsConfig({
    required this.filePath,
    this.groups = const {},
    this.diagnostics = const [],
  });

  final String filePath;
  final Map<String, WritersideInstanceGroup> groups;
  final List<Diagnostic> diagnostics;
}

class WritersideSettingsConfig {
  const WritersideSettingsConfig({
    this.capsRules = const [],
    this.defaultProperties = const [],
    this.disableWebNamePreprocessing,
    this.smartIgnoreVars,
    this.wrsSupernovaUseVersion,
  });

  final List<WritersideCapsRule> capsRules;
  final List<WritersideDefaultProperty> defaultProperties;
  final bool? disableWebNamePreprocessing;
  final bool? smartIgnoreVars;
  final String? wrsSupernovaUseVersion;
}

class WritersideCapsRule {
  const WritersideCapsRule({required this.style, required this.target});

  final String? style;
  final String? target;
}

class WritersideDefaultProperty {
  const WritersideDefaultProperty({
    required this.elementName,
    required this.propertyName,
    required this.value,
  });

  final String? elementName;
  final String? propertyName;
  final String? value;
}

class WritersideConfig {
  const WritersideConfig({
    required this.filePath,
    required this.version,
    required this.moduleName,
    required this.topicRoots,
    required this.imageRoots,
    required this.apiSpecificationsDir,
    required this.apiSpecificationsExplicit,
    required this.buildConfigDir,
    required this.buildConfigExplicit,
    required this.snippetsDir,
    required this.resourcesFile,
    required this.resourcesDir,
    required this.varsFile,
    required this.categoriesFile,
    required this.instanceGroupsFile,
    required this.instances,
    required this.settings,
    required this.diagnostics,
  });

  final String filePath;
  final String? version;
  final String? moduleName;
  final List<WritersideTopicRoot> topicRoots;
  final List<WritersideImageRoot> imageRoots;
  final String apiSpecificationsDir;
  final bool apiSpecificationsExplicit;
  final String buildConfigDir;
  final bool buildConfigExplicit;
  final String? snippetsDir;
  final String? resourcesFile;
  final String? resourcesDir;
  final String? varsFile;
  final String? categoriesFile;
  final String? instanceGroupsFile;
  final List<WritersideConfiguredInstance> instances;
  final WritersideSettingsConfig settings;
  final List<Diagnostic> diagnostics;

  String get configFileName => p.basename(filePath);
  String get fileName => configFileName;
  String get topicsDir => topicRoots.firstOrNull?.dir ?? 'topics';
  List<String> get topicsDirs => [for (final root in topicRoots) root.dir];
  String get imagesDir => imageRoots.firstOrNull?.dir ?? 'images';
  List<String> get imagesDirs => [for (final root in imageRoots) root.dir];
  List<String> get instanceSources => [
    for (final instance in instances) instance.src,
  ];
}

sealed class WritersideTreeEntry {
  const WritersideTreeEntry();

  SourceSpan get span;
  String? get instanceCondition;
  String? get customFilter;
  String? get origin;
}

class WritersideTocInclude extends WritersideTreeEntry {
  const WritersideTocInclude({
    required this.from,
    required this.elementId,
    required this.span,
    this.instanceCondition,
    this.customFilter,
    this.origin,
    this.useFilters = const [],
  });

  final String? from;
  final String? elementId;
  @override
  final SourceSpan span;
  @override
  final String? instanceCondition;
  @override
  final String? customFilter;
  @override
  final String? origin;
  final List<String> useFilters;
}

class WritersideTocSnippet extends WritersideTreeEntry {
  const WritersideTocSnippet({
    required this.id,
    required this.entries,
    required this.span,
    this.instanceCondition,
    this.customFilter,
    this.origin,
  });

  final String? id;
  final List<WritersideTreeEntry> entries;
  @override
  final SourceSpan span;
  @override
  final String? instanceCondition;
  @override
  final String? customFilter;
  @override
  final String? origin;
}

class TocNode extends WritersideTreeEntry {
  const TocNode({
    required this.hidden,
    required this.children,
    required this.span,
    this.topicFileName,
    this.referenceTopicFileName,
    this.referenceInstanceId,
    this.href,
    this.tocTitle,
    this.id,
    this.acceptsWebFileNames,
    this.acceptsWebFileNamesRef,
    this.targetForAcceptWebFileNames,
    this.instanceCondition,
    this.customFilter,
    this.origin,
    this.workInProgress = false,
    this.entries = const [],
    this.sourceTreePath,
    this.sourceTocPath,
    this.included = false,
    this.includeFrom,
    this.includeElementId,
    this.includeResolutionError,
  });

  final String? topicFileName;
  final String? referenceTopicFileName;
  final String? referenceInstanceId;
  final String? href;
  final String? tocTitle;
  final String? id;
  final String? acceptsWebFileNames;
  final String? acceptsWebFileNamesRef;
  final String? targetForAcceptWebFileNames;
  @override
  final String? instanceCondition;
  @override
  final String? customFilter;
  @override
  final String? origin;
  final bool hidden;
  final bool workInProgress;
  final List<TocNode> children;
  final List<WritersideTreeEntry> entries;
  final String? sourceTreePath;
  final List<int>? sourceTocPath;
  final bool included;
  final String? includeFrom;
  final String? includeElementId;
  final String? includeResolutionError;
  @override
  final SourceSpan span;

  String? get topicReference => topicFileName ?? referenceTopicFileName;

  List<WritersideTreeEntry> get childEntries {
    if (entries.isNotEmpty || children.isEmpty) {
      return entries;
    }
    return children;
  }

  bool get canEditStructure =>
      !included && sourceTreePath != null && sourceTocPath != null;

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
    this.version,
    this.globalVersion,
    this.webPath,
    this.keymapsMode,
    this.allowSearchEngineIndexing = false,
    this.offlineArtifact = false,
    this.treeEntries = const [],
    this.resolvedTocRoots,
  });

  final String id;
  final String name;
  final String sourceTreePath;
  final String? startPage;
  final String status;
  final bool isLibrary;
  final List<TocNode> tocRoots;
  final List<Diagnostic> diagnostics;
  final String? version;
  final String? globalVersion;
  final String? webPath;
  final String? keymapsMode;
  final bool allowSearchEngineIndexing;
  final bool offlineArtifact;
  final List<WritersideTreeEntry> treeEntries;
  final List<TocNode>? resolvedTocRoots;

  String? get effectiveVersion => version ?? globalVersion;

  List<TocNode> get navigationTocRoots => resolvedTocRoots ?? tocRoots;

  Set<String> get topicFileSet {
    return navigationTocRoots
        .expand((node) => node.flatten())
        .map((node) => node.topicReference)
        .whereType<String>()
        .toSet();
  }

  WritersideInstance withResolvedTocRoots(List<TocNode> roots) {
    return WritersideInstance(
      id: id,
      name: name,
      sourceTreePath: sourceTreePath,
      startPage: startPage,
      status: status,
      isLibrary: isLibrary,
      tocRoots: tocRoots,
      diagnostics: diagnostics,
      version: version,
      globalVersion: globalVersion,
      webPath: webPath,
      keymapsMode: keymapsMode,
      allowSearchEngineIndexing: allowSearchEngineIndexing,
      offlineArtifact: offlineArtifact,
      treeEntries: treeEntries,
      resolvedTocRoots: roots,
    );
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

class WritersideTopicTitleOverride {
  const WritersideTopicTitleOverride({
    required this.instance,
    required this.title,
  });

  final String instance;
  final String title;
}

class WritersideTopic {
  const WritersideTopic({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.topicRoot,
    required this.format,
    required this.title,
    required this.elementIds,
    required this.links,
    required this.images,
    required this.variables,
    required this.includes,
    required this.diagnostics,
    this.webFileName,
    this.markdown,
    this.titleOverrides = const [],
    this.semanticElementNames = const [],
  });

  final String id;
  final String filePath;
  final String fileName;
  final String topicRoot;
  final WritersideTopicFormat format;
  final String? title;
  final List<WritersideElementId> elementIds;
  final List<MarkdownLink> links;
  final List<MarkdownImage> images;
  final List<MarkdownVariableToken> variables;
  final List<WritersideInclude> includes;
  final List<Diagnostic> diagnostics;
  final String? webFileName;
  final ParsedMarkdownDocument? markdown;
  final List<WritersideTopicTitleOverride> titleOverrides;
  final List<String> semanticElementNames;

  String get baseName => p.basename(fileName);
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
    required this.validatedImageDirs,
    this.buildProfiles,
    this.instanceGroups,
  });

  final String rootPath;
  final WritersideConfig config;
  final List<WritersideInstance> instances;
  final List<WritersideTopic> topics;
  final List<WritersideVariable> variables;
  final List<WritersideCategory> categories;
  final List<Diagnostic> diagnostics;
  final List<String> validatedImageDirs;
  final WritersideBuildProfilesConfig? buildProfiles;
  final WritersideInstanceGroupsConfig? instanceGroups;

  String get effectiveImagesDir => validatedImageDirs.firstOrNull ?? 'images';

  Map<String, WritersideTopic> get topicsByFileName {
    final grouped = <String, List<WritersideTopic>>{};
    for (final topic in topics) {
      grouped.putIfAbsent(topic.fileName, () => []).add(topic);
    }
    return {
      for (final entry in grouped.entries)
        if (entry.value.length == 1) entry.key: entry.value.single,
    };
  }

  Map<String, WritersideTopic> get topicsById => {
    for (final topic in topics) topic.id: topic,
  };

  WritersideTopic? topicByReference(
    String reference, {
    WritersideTopic? fromTopic,
  }) {
    return topicsMatchingReference(
      reference,
      fromTopic: fromTopic,
    ).singleOrNull;
  }

  List<WritersideTopic> topicsMatchingReference(
    String reference, {
    WritersideTopic? fromTopic,
  }) {
    final normalized = _normalizedTopicReference(reference);
    if (normalized.isEmpty) {
      return fromTopic == null ? const [] : [fromTopic];
    }
    final candidates = <String>[
      if (fromTopic != null && !p.isAbsolute(normalized))
        _normalizedTopicReference(
          p.join(p.dirname(fromTopic.fileName), normalized),
        ),
      normalized,
    ];
    for (final candidate in candidates.toSet()) {
      final exact = topics
          .where((topic) => topic.fileName == candidate)
          .toList();
      if (exact.isNotEmpty) {
        return exact;
      }
    }
    final basename = p.basename(normalized);
    return topics.where((topic) => topic.baseName == basename).toList();
  }

  Set<String> get variableNames => {
    for (final variable in variables) variable.name,
    'instance',
    'instance-lowercase',
    'currentId',
    'thisTopic',
  };
}

String _normalizedTopicReference(String value) {
  return p.normalize(value.trim()).replaceAll(r'\', '/');
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get singleOrNull => length == 1 ? single : null;
}
