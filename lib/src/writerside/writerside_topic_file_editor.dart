import 'dart:io';

// HtmlParser exposes its tokenizer but does not expose per-attribute source
// spans. Use the package tokenizer so raw HTML references are interpreted with
// the same HTML rules as BusyMark's Markdown parser.
// ignore: implementation_imports
import 'package:html/src/token.dart' show StartTagToken;
// ignore: implementation_imports
import 'package:html/src/tokenizer.dart' show HtmlTokenizer;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_ast_adapter.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'writerside_model.dart';
import 'writerside_module_service.dart';
import 'writerside_project.dart';
import 'writerside_schema.dart';
import 'writerside_topic_file_name.dart';
import 'writerside_web_file_name.dart';

class WritersideTopicRenameFileChange {
  const WritersideTopicRenameFileChange({
    required this.path,
    required this.originalSource,
    required this.resultingSource,
  });

  final String path;
  final String originalSource;
  final String resultingSource;
}

class WritersideTopicRenameUrlChange {
  const WritersideTopicRenameUrlChange({
    required this.moduleRoot,
    required this.instanceId,
    required this.oldWebFileName,
    required this.newWebFileName,
  });

  final String moduleRoot;
  final String instanceId;
  final String oldWebFileName;
  final String newWebFileName;

  bool get changed => oldWebFileName != newWebFileName;
}

/// An immutable, fully calculated topic-file refactoring. Applying this object
/// never recalculates reference edits; every participating source is checked
/// against the captured snapshots before the first write.
class WritersideTopicRenamePlan {
  WritersideTopicRenamePlan._({
    required this.owningModule,
    required this.oldTopicPath,
    required this.newTopicPath,
    required this.oldTopicReference,
    required this.newTopicReference,
    required this.oldTopicId,
    required this.newTopicId,
    required this.format,
    required this.originalTargetSource,
    required this.resultingTargetSource,
    required List<WritersideTopicRenameFileChange> changedFiles,
    required this.createsNewTopicFile,
    required this.deletesOldTopicFile,
    required this.updatesXmlTopicId,
    required Set<String> affectedPaths,
    required List<WritersideTopicRenameUrlChange> webFileNameChanges,
    required _PreparedTopicRename prepared,
  }) : changedFiles = List.unmodifiable(changedFiles),
       affectedPaths = Set.unmodifiable(affectedPaths),
       webFileNameChanges = List.unmodifiable(webFileNameChanges),
       _prepared = prepared;

  final WritersideModule owningModule;
  final String oldTopicPath;
  final String newTopicPath;
  final String oldTopicReference;
  final String newTopicReference;
  final String oldTopicId;
  final String newTopicId;
  final WritersideTopicFormat format;
  final String originalTargetSource;
  final String resultingTargetSource;
  final List<WritersideTopicRenameFileChange> changedFiles;
  final bool createsNewTopicFile;
  final bool deletesOldTopicFile;
  final bool updatesXmlTopicId;
  final Set<String> affectedPaths;
  final List<WritersideTopicRenameUrlChange> webFileNameChanges;
  final _PreparedTopicRename _prepared;
}

class WritersideTopicFileRenameResult {
  const WritersideTopicFileRenameResult({
    required this.oldTopicPath,
    required this.newTopicPath,
    required this.oldTopicFileName,
    required this.newTopicFileName,
    required this.updatedTreePaths,
    required this.updatedXmlTopicId,
  });

  final String oldTopicPath;
  final String newTopicPath;
  final String oldTopicFileName;
  final String newTopicFileName;
  final List<String> updatedTreePaths;
  final bool updatedXmlTopicId;
}

class WritersideTopicFileDeleteResult {
  const WritersideTopicFileDeleteResult({
    required this.deletedTopicPath,
    required this.updatedTreePaths,
    required this.removedTocEntries,
  });

  final String deletedTopicPath;
  final List<String> updatedTreePaths;
  final int removedTocEntries;
}

/// Mutates a resolved Writerside topic file and every semantically resolved
/// project reference supplied to the rename transaction.
///
/// Topic files and instance trees must be regular files below the module's
/// canonical root. Symlinked path components and paths outside that root are
/// rejected before any mutation is attempted.
class WritersideTopicFileEditor {
  const WritersideTopicFileEditor({
    this.moduleService = const WritersideModuleService(),
    Future<void> Function(String targetPath)? beforeNewFileCreate,
    Future<void> Function(String treePath)? beforeTreePublish,
  }) : _beforeNewFileCreate = beforeNewFileCreate,
       _beforeTreePublish = beforeTreePublish;

  final WritersideModuleService moduleService;
  final Future<void> Function(String targetPath)? _beforeNewFileCreate;
  final Future<void> Function(String treePath)? _beforeTreePublish;

  Future<WritersideTopicFileRenameResult> rename({
    required WritersideModule module,
    required WritersideTopic topic,
    required String newFileName,
    List<WritersideModule>? projectModules,
    void Function(Iterable<String>)? validateBeforePublish,
  }) async {
    final plan = await prepareRename(
      module: module,
      topic: topic,
      newFileName: newFileName,
      projectModules: projectModules,
    );
    return applyRename(plan, validateBeforePublish: validateBeforePublish);
  }

  Future<WritersideTopicRenamePlan> prepareRename({
    required WritersideModule module,
    required WritersideTopic topic,
    required String newFileName,
    List<WritersideModule>? projectModules,
  }) async {
    final snapshot = await _currentModuleSnapshot(module, topic);
    final context = await _mutationContext(snapshot);
    final referenceContexts = <_ReferenceModuleContext>[
      _ReferenceModuleContext.fromMutation(context),
    ];
    for (final candidate in projectModules ?? const <WritersideModule>[]) {
      if (p.equals(candidate.rootPath, context.module.rootPath)) continue;
      referenceContexts.add(await _referenceModuleContext(candidate));
    }
    final safeFileName = _safeRenamedFileName(
      newFileName,
      oldPath: context.topicPath,
    );
    final targetPath = p.join(p.dirname(context.topicPath), safeFileName);
    final newTopicFileName = _renamedTopicFileName(
      context.topic.fileName,
      safeFileName,
    );
    if (p.equals(targetPath, context.topicPath)) {
      return WritersideTopicRenamePlan._(
        owningModule: context.module,
        oldTopicPath: context.topicPath,
        newTopicPath: context.topicPath,
        oldTopicReference: context.topic.fileName,
        newTopicReference: context.topic.fileName,
        oldTopicId: context.topic.id,
        newTopicId: context.topic.id,
        format: context.topic.format,
        originalTargetSource: context.topicSource,
        resultingTargetSource: context.topicSource,
        changedFiles: const [],
        createsNewTopicFile: false,
        deletesOldTopicFile: false,
        updatesXmlTopicId: false,
        affectedPaths: {context.topicPath},
        webFileNameChanges: const [],
        prepared: _PreparedTopicRename(
          target: context,
          referenceContexts: referenceContexts,
          targetSource: context.topicSource,
          publishedEdits: const [],
        ),
      );
    }

    await _validateRenameTarget(
      context,
      targetPath: targetPath,
      newTopicFileName: newTopicFileName,
      newFileName: safeFileName,
    );
    final referenceEdits = _renameProjectReferenceEdits(
      referenceContexts,
      target: context,
      newTopicFileName: newTopicFileName,
      newFileName: safeFileName,
    );
    final targetReferenceEdit = referenceEdits
        .where((edit) => p.equals(edit.path, context.topicPath))
        .singleOrNull;
    final topicEdit = _renamedTopicSource(
      path: context.topicPath,
      source: targetReferenceEdit?.updatedSource ?? context.topicSource,
      newFileName: safeFileName,
    );
    final publishedEdits = referenceEdits
        .where((edit) => !p.equals(edit.path, context.topicPath))
        .toList();

    _validateGeneratedXmlRenameSources(
      referenceContexts,
      target: context,
      targetSource: topicEdit.source,
      publishedEdits: publishedEdits,
    );

    final webFileNameChanges = _validateProspectiveWebFileNames(
      referenceContexts,
      target: context,
      newTopicFileName: newTopicFileName,
    );

    final affectedPaths = <String>{
      context.topicPath,
      targetPath,
      for (final edit in publishedEdits) edit.path,
    };
    return WritersideTopicRenamePlan._(
      owningModule: context.module,
      oldTopicPath: context.topicPath,
      newTopicPath: targetPath,
      oldTopicReference: context.topic.fileName,
      newTopicReference: newTopicFileName,
      oldTopicId: p.basenameWithoutExtension(context.topic.fileName),
      newTopicId: p.basenameWithoutExtension(newTopicFileName),
      format: context.topic.format,
      originalTargetSource: context.topicSource,
      resultingTargetSource: topicEdit.source,
      changedFiles: [
        for (final edit in publishedEdits)
          WritersideTopicRenameFileChange(
            path: edit.path,
            originalSource: edit.originalSource,
            resultingSource: edit.updatedSource,
          ),
      ],
      createsNewTopicFile: true,
      deletesOldTopicFile: true,
      updatesXmlTopicId: topicEdit.updatedXmlTopicId,
      affectedPaths: affectedPaths,
      webFileNameChanges: webFileNameChanges,
      prepared: _PreparedTopicRename(
        target: context,
        referenceContexts: referenceContexts,
        targetSource: topicEdit.source,
        publishedEdits: publishedEdits,
      ),
    );
  }

  Future<WritersideTopicFileRenameResult> applyRename(
    WritersideTopicRenamePlan plan, {
    void Function(Iterable<String>)? validateBeforePublish,
  }) async {
    final prepared = plan._prepared;
    final context = prepared.target;
    final referenceContexts = prepared.referenceContexts;
    final publishedEdits = prepared.publishedEdits;
    if (!plan.createsNewTopicFile) {
      return WritersideTopicFileRenameResult(
        oldTopicPath: plan.oldTopicPath,
        newTopicPath: plan.newTopicPath,
        oldTopicFileName: plan.oldTopicReference,
        newTopicFileName: plan.newTopicReference,
        updatedTreePaths: const [],
        updatedXmlTopicId: false,
      );
    }

    validateBeforePublish?.call(plan.affectedPaths);
    await _ensurePreparedPlanUnchanged(plan);
    validateBeforePublish?.call(plan.affectedPaths);

    await _writeNewFile(
      context.anchor,
      plan.newTopicPath,
      prepared.targetSource,
      sourceStat: context.topicStat,
    );
    final appliedTreeEdits = <_TreeEdit>[];
    try {
      validateBeforePublish?.call(plan.affectedPaths);
      await _applyTreeEdits(
        context.anchor,
        publishedEdits,
        applied: appliedTreeEdits,
      );
      validateBeforePublish?.call(plan.affectedPaths);
      await _ensureReferenceContextsUnchanged(
        referenceContexts,
        publishedEdits,
        targetPath: plan.newTopicPath,
        targetSource: prepared.targetSource,
        targetModuleRoot: context.module.rootPath,
      );
      await _deleteUnchangedTopicSource(context);
    } on Object {
      final restored = await _rollbackTreeEdits(
        context.anchor,
        appliedTreeEdits,
      );
      final safeToCleanUp =
          restored &&
          await _renameTargetIsSafeToCleanUp(
            context,
            targetPath: plan.newTopicPath,
            targetSource: prepared.targetSource,
          );
      if (safeToCleanUp) {
        await _deleteCreatedFileBestEffort(
          context.anchor,
          plan.newTopicPath,
          prepared.targetSource,
        );
      }
      rethrow;
    }

    return WritersideTopicFileRenameResult(
      oldTopicPath: plan.oldTopicPath,
      newTopicPath: plan.newTopicPath,
      oldTopicFileName: plan.oldTopicReference,
      newTopicFileName: plan.newTopicReference,
      updatedTreePaths: List.unmodifiable([
        for (final edit in publishedEdits)
          if (_isTreePath(edit.path)) edit.path,
      ]),
      updatedXmlTopicId: plan.updatesXmlTopicId,
    );
  }

  Future<WritersideTopicFileDeleteResult> delete({
    required WritersideModule module,
    required WritersideTopic topic,
  }) async {
    final snapshot = await _currentModuleSnapshot(module, topic);
    final context = await _mutationContext(snapshot);
    final treeMutation = await _deleteTreeEdits(context);
    final appliedTreeEdits = <_TreeEdit>[];
    try {
      await _applyTreeEdits(
        context.anchor,
        treeMutation.edits,
        applied: appliedTreeEdits,
      );
      await _ensureTreesAtExpectedSources(context, treeMutation.edits);
      await _ensureConfigurationUnchanged(context);
      await _ensureTopicSourcesUnchanged(context);
      await _deleteUnchangedTopicSource(context);
    } on Object {
      await _rollbackTreeEdits(context.anchor, appliedTreeEdits);
      rethrow;
    }

    return WritersideTopicFileDeleteResult(
      deletedTopicPath: context.topicPath,
      updatedTreePaths: List.unmodifiable([
        for (final edit in treeMutation.edits) edit.path,
      ]),
      removedTocEntries: treeMutation.removedTocEntries,
    );
  }

  Future<_CurrentModuleSnapshot> _currentModuleSnapshot(
    WritersideModule suppliedModule,
    WritersideTopic requestedTopic,
  ) async {
    final suppliedAnchor = await _moduleAnchor(suppliedModule.rootPath);
    await _resolvePath(
      suppliedAnchor,
      requestedTopic.filePath,
      allowRoot: false,
    );
    final before = await _configurationSources(suppliedModule.rootPath);
    final initiallyLoadedModule = await moduleService.load(
      suppliedModule.rootPath,
    );
    final topicSourcesBefore = await _topicSources(
      suppliedAnchor,
      initiallyLoadedModule,
    );
    final module = await moduleService.load(suppliedModule.rootPath);
    final topicSourcesAfter = await _topicSources(suppliedAnchor, module);
    final after = await _configurationSources(suppliedModule.rootPath);
    if (!_sameStringMap(before, after) ||
        !_sameStringMap(topicSourcesBefore, topicSourcesAfter)) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': module.config.filePath},
      );
    }
    if (module.instances.length != module.config.instanceSources.length) {
      throw BusyMarkException(
        'writerside.topic-file.tree-missing',
        args: {'path': module.config.filePath},
      );
    }
    WritersideTopic? topic;
    for (final candidate in module.topics) {
      if (p.equals(candidate.filePath, requestedTopic.filePath)) {
        topic = candidate;
        break;
      }
    }
    if (topic == null) {
      throw BusyMarkException(
        'writerside.topic-file.topic-not-resolved',
        args: {'path': requestedTopic.filePath},
      );
    }
    return _CurrentModuleSnapshot(
      module: module,
      topic: topic,
      configurationSources: after,
      topicSources: topicSourcesAfter,
    );
  }

  Future<Map<String, String?>> _configurationSources(String rootPath) async {
    final result = <String, String?>{};
    for (final fileName in const ['writerside.cfg', 'project.ihp']) {
      final path = normalizePath(p.join(rootPath, fileName));
      final file = File(path);
      result[path] = await file.exists() ? await file.readAsString() : null;
    }
    return result;
  }

  Future<Map<String, String>> _topicSources(
    CanonicalPathAnchor anchor,
    WritersideModule module,
  ) async {
    final result = <String, String>{};
    for (final topicRoot in module.config.topicRoots) {
      final root = await _resolvePath(
        anchor,
        p.join(module.rootPath, topicRoot.dir),
        allowRoot: true,
      );
      if (root.type == FileSystemEntityType.notFound) {
        continue;
      }
      if (root.type != FileSystemEntityType.directory) {
        throw BusyMarkException(
          'writerside.topic-file.topic-inventory-changed',
          args: {'path': root.path},
        );
      }
      final candidatePaths = <String>[];
      try {
        await for (final entity in Directory(
          root.path,
        ).list(recursive: true, followLinks: false)) {
          final extension = p.extension(entity.path).toLowerCase();
          if (!{'.md', '.markdown', '.topic'}.contains(extension)) {
            continue;
          }
          final type = await FileSystemEntity.type(
            entity.path,
            followLinks: false,
          );
          if (type == FileSystemEntityType.file) {
            candidatePaths.add(normalizePath(entity.path));
          }
        }
      } on FileSystemException catch (error) {
        throw BusyMarkException(
          'writerside.topic-file.topic-inventory-changed',
          args: {'path': error.path ?? root.path},
        );
      }
      candidatePaths.sort();
      for (final candidatePath in candidatePaths) {
        final resolution = await _resolvePath(
          anchor,
          candidatePath,
          allowRoot: false,
        );
        if (resolution.type != FileSystemEntityType.file) {
          throw BusyMarkException(
            'writerside.topic-file.topic-inventory-changed',
            args: {'path': resolution.path},
          );
        }
        try {
          result[resolution.path] = await File(resolution.path).readAsString();
        } on FileSystemException catch (error) {
          throw BusyMarkException(
            'writerside.topic-file.topic-inventory-changed',
            args: {'path': error.path ?? resolution.path},
          );
        }
      }
    }
    return result;
  }

  Future<_MutationContext> _mutationContext(
    _CurrentModuleSnapshot snapshot,
  ) async {
    final module = snapshot.module;
    final requestedTopic = snapshot.topic;
    final anchor = await _moduleAnchor(module.rootPath);
    final topicResolution = await _resolvePath(
      anchor,
      requestedTopic.filePath,
      allowRoot: false,
    );
    if (topicResolution.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic-file.source-missing',
        args: {'path': topicResolution.path},
      );
    }
    final resolvedTopics = module.topics
        .where(
          (candidate) =>
              p.equals(normalizePath(candidate.filePath), topicResolution.path),
        )
        .toList();
    if (resolvedTopics.length != 1) {
      throw BusyMarkException(
        'writerside.topic-file.topic-not-resolved',
        args: {'path': topicResolution.path},
      );
    }
    final topic = resolvedTopics.single;
    final topicRootResolution = await _resolvePath(
      anchor,
      topic.topicRoot,
      allowRoot: true,
    );
    if (topicRootResolution.type != FileSystemEntityType.directory ||
        !p.isWithin(topicRootResolution.path, topicResolution.path)) {
      throw BusyMarkException(
        'writerside.topic-file.source-unsafe',
        args: {'path': topicResolution.path},
      );
    }
    final actualFileName = normalizedRelative(
      topicRootResolution.path,
      topicResolution.path,
    );
    if (actualFileName != _normalizedReference(topic.fileName)) {
      throw BusyMarkException(
        'writerside.topic-file.source-unsafe',
        args: {'path': topicResolution.path},
      );
    }
    final topicFile = File(topicResolution.path);
    final topicSource = await topicFile.readAsString();
    final topicStat = await topicFile.stat();
    final trees = await _loadTrees(anchor, module);
    return _MutationContext(
      anchor: anchor,
      module: module,
      topic: topic,
      topicPath: topicResolution.path,
      topicSource: topicSource,
      topicStat: topicStat,
      configurationSources: snapshot.configurationSources,
      topicSources: snapshot.topicSources,
      trees: trees,
    );
  }

  Future<_ReferenceModuleContext> _referenceModuleContext(
    WritersideModule suppliedModule,
  ) async {
    final anchor = await _moduleAnchor(suppliedModule.rootPath);
    final configurationBefore = await _configurationSources(
      suppliedModule.rootPath,
    );
    final initiallyLoaded = await moduleService.load(suppliedModule.rootPath);
    final topicSourcesBefore = await _topicSources(anchor, initiallyLoaded);
    final module = await moduleService.load(suppliedModule.rootPath);
    final topicSources = await _topicSources(anchor, module);
    final configurationSources = await _configurationSources(module.rootPath);
    if (!_sameStringMap(configurationBefore, configurationSources) ||
        !_sameStringMap(topicSourcesBefore, topicSources) ||
        module.instances.length != module.config.instanceSources.length) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': module.config.filePath},
      );
    }
    return _ReferenceModuleContext(
      anchor: anchor,
      module: module,
      configurationSources: configurationSources,
      topicSources: topicSources,
      trees: await _loadTrees(anchor, module),
    );
  }

  Future<CanonicalPathAnchor> _moduleAnchor(String rootPath) async {
    try {
      final anchor = await captureCanonicalDirectoryAnchor(
        normalizePath(rootPath),
      );
      if (!p.equals(anchor.requestedRootPath, anchor.rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootReplacement,
          path: anchor.requestedRootPath,
        );
      }
      return anchor;
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic-file.module-root-unsafe',
        args: {'path': error.path},
      );
    }
  }

  Future<List<_LoadedTree>> _loadTrees(
    CanonicalPathAnchor anchor,
    WritersideModule module,
  ) async {
    final trees = <_LoadedTree>[];
    final seenPaths = <String>{};
    for (final instance in module.instances) {
      final resolution = await _resolvePath(
        anchor,
        instance.sourceTreePath,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.file) {
        throw BusyMarkException(
          'writerside.topic-file.tree-missing',
          args: {'path': resolution.path},
        );
      }
      if (!seenPaths.add(resolution.path)) {
        continue;
      }
      final source = await File(resolution.path).readAsString();
      final XmlDocument document;
      try {
        document = XmlDocument.parse(source);
      } on Object catch (error) {
        throw BusyMarkException(
          'writerside.topic-file.tree-invalid',
          args: {'path': resolution.path, 'error': '$error'},
        );
      }
      if (document.rootElement.name.local != 'instance-profile') {
        throw BusyMarkException(
          'writerside.topic-file.tree-invalid',
          args: {'path': resolution.path},
        );
      }
      trees.add(
        _LoadedTree(path: resolution.path, source: source, document: document),
      );
    }
    return trees;
  }

  Future<void> _validateRenameTarget(
    _MutationContext context, {
    required String targetPath,
    required String newTopicFileName,
    required String newFileName,
  }) async {
    final target = await _resolvePath(
      context.anchor,
      targetPath,
      allowRoot: false,
    );
    if (target.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.topic-file.target-exists',
        args: {'path': target.path},
      );
    }
    final newId = p.basenameWithoutExtension(newFileName);
    for (final candidate in context.module.topics) {
      if (p.equals(normalizePath(candidate.filePath), context.topicPath)) {
        continue;
      }
      if (candidate.id == newId ||
          _normalizedReference(candidate.fileName) == newTopicFileName) {
        throw BusyMarkException(
          'writerside.topic-file.duplicate-target',
          args: {'fileName': newTopicFileName, 'topicId': newId},
        );
      }
    }
  }

  List<WritersideTopicRenameUrlChange> _validateProspectiveWebFileNames(
    List<_ReferenceModuleContext> contexts, {
    required _MutationContext target,
    required String newTopicFileName,
  }) {
    final modules = [for (final context in contexts) context.module];
    final origins = <String, WritersideModule>{
      for (final module in modules)
        (module.config.moduleName?.trim().isNotEmpty == true
                ? module.config.moduleName!.trim()
                : p.basename(module.rootPath)):
            module,
    };
    const resolver = WritersideWebFileNameResolver();
    final result = <WritersideTopicRenameUrlChange>[];
    for (final host in modules) {
      for (final instance in host.instances.where(
        (value) => !value.isLibrary,
      )) {
        final published = writersidePublishedTopicsForInstance(
          hostModule: host,
          instance: instance,
          modulesByOrigin: origins,
        );
        final publishesTarget = published.any(
          (item) =>
              p.equals(item.sourceModule.rootPath, target.module.rootPath) &&
              p.equals(item.topic.filePath, target.topicPath),
        );
        if (!publishesTarget) continue;
        final oldEffective = resolver.resolve(
          module: target.module,
          topic: target.topic,
          instance: instance,
          modulesByOrigin: origins,
        );
        final newEffective = resolver.resolve(
          module: target.module,
          topic: target.topic,
          instance: instance,
          modulesByOrigin: origins,
          topicFileName: newTopicFileName,
        );
        if (!newEffective.isValid) {
          throw BusyMarkException(
            'writerside.topic-file.web-file-name-invalid',
            args: {
              'instanceId': instance.id,
              'webFileName': newEffective.value,
              'topic': newTopicFileName,
            },
          );
        }
        for (final other in published) {
          if (p.equals(other.sourceModule.rootPath, target.module.rootPath) &&
              p.equals(other.topic.filePath, target.topicPath)) {
            continue;
          }
          final otherEffective = resolver.resolve(
            module: other.sourceModule,
            topic: other.topic,
            instance: instance,
            modulesByOrigin: origins,
          );
          if (otherEffective.isValid &&
              otherEffective.value.toLowerCase() ==
                  newEffective.value.toLowerCase()) {
            throw BusyMarkException(
              'writerside.topic-file.web-file-name-collision',
              args: {
                'instanceId': instance.id,
                'webFileName': newEffective.value,
                'firstTopic': newTopicFileName,
                'secondTopic': other.topic.fileName,
              },
            );
          }
        }
        result.add(
          WritersideTopicRenameUrlChange(
            moduleRoot: host.rootPath,
            instanceId: instance.id,
            oldWebFileName: oldEffective.value,
            newWebFileName: newEffective.value,
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  List<_TreeEdit> _renameProjectReferenceEdits(
    List<_ReferenceModuleContext> contexts, {
    required _MutationContext target,
    required String newTopicFileName,
    required String newFileName,
  }) {
    final modules = [for (final context in contexts) context.module];
    final index = WritersideProjectIndex.build(modules);
    final topicsByPath = <String, WritersideTopic>{
      for (final context in contexts)
        for (final topic in context.module.topics)
          normalizePath(topic.filePath): topic,
    };
    final usages = <String, WritersideReference>{};
    final xmlAttributeSpans = <String>{};
    final htmlAttributeQuotes = <String, _HtmlAttributeQuote>{};
    final markdownDestinationSpans = <String>{};
    final markdownAngleDestinationSpans = <String>{};
    for (final usage in index.references) {
      if (usage.kind != WritersideSymbolKind.topic) continue;
      final containingTopic = topicsByPath[normalizePath(usage.filePath)];
      if (containingTopic == null) continue;
      final writable = _indexedWritableTopicReference(containingTopic, usage);
      if (writable == null) continue;
      final writableUsage = writable.reference;
      final topicPart = usage.value.split('#').first;
      if (topicPart.isEmpty ||
          !index
              .definitions(
                topicPart,
                moduleId: usage.moduleId,
                origin: usage.origin,
                kind: WritersideSymbolKind.topic,
                filePath: usage.filePath,
                referenceOffset: usage.span.startOffset,
              )
              .any((symbol) => p.equals(symbol.filePath, target.topicPath))) {
        continue;
      }
      final key =
          '${writableUsage.filePath}:${writableUsage.span.startOffset}:'
          '${writableUsage.span.endOffset}:'
          '${writableUsage.sourceValue ?? writableUsage.value}';
      usages[key] = writableUsage;
      if (writable.xmlAttribute) {
        xmlAttributeSpans.add(_referenceSpanKey(writableUsage));
      }
    }
    // The Markdown AST may assign several inline links one broad source span.
    // The general project index intentionally coalesces such semantic entries;
    // rename still needs every concrete destination occurrence.
    for (final context in contexts) {
      final moduleId = index.modulesById.entries
          .where(
            (entry) => p.equals(entry.value.rootPath, context.module.rootPath),
          )
          .map((entry) => entry.key)
          .single;
      for (final topic in context.module.topics) {
        if (topic.format != WritersideTopicFormat.markdown) continue;
        final projection = _authoredMarkdownTopicReferences(topic);
        for (final unbound in projection.unboundLinks) {
          final topicPart = unbound.destination.split('#').first;
          final resolvesInRecordedScope =
              topicPart.isNotEmpty &&
              index
                  .definitions(
                    topicPart,
                    moduleId: moduleId,
                    origin: unbound.origin,
                    kind: WritersideSymbolKind.topic,
                    filePath: topic.filePath,
                    referenceOffset: unbound.span.startOffset,
                  )
                  .any((symbol) => p.equals(symbol.filePath, target.topicPath));
          final resolvesConservativelyToTarget =
              topicPart.isNotEmpty &&
              unbound.origin == null &&
              target.module
                  .topicsMatchingReference(topicPart)
                  .any(
                    (candidate) =>
                        p.equals(candidate.filePath, target.topicPath),
                  );
          if (resolvesInRecordedScope || resolvesConservativelyToTarget) {
            throw BusyMarkException(
              'writerside.topic-file.ambiguous-reference',
              args: {
                'reference': unbound.destination,
                'treePath': topic.filePath,
              },
            );
          }
        }
        for (final reference in projection.references) {
          final topicPart = reference.destination.split('#').first;
          if (topicPart.isEmpty ||
              !index
                  .definitions(
                    topicPart,
                    moduleId: moduleId,
                    origin: reference.origin,
                    kind: WritersideSymbolKind.topic,
                    filePath: topic.filePath,
                    referenceOffset: reference.occurrenceOffset,
                  )
                  .any(
                    (symbol) => p.equals(symbol.filePath, target.topicPath),
                  )) {
            continue;
          }
          final usage = WritersideReference(
            value: reference.destination,
            kind: WritersideSymbolKind.topic,
            moduleId: moduleId,
            filePath: topic.filePath,
            span: reference.destinationSpan,
            origin: reference.origin,
            sourceValue: reference.rawDestination,
          );
          final key =
              '${usage.filePath}:${usage.span.startOffset}:'
              '${usage.span.endOffset}:${usage.sourceValue}';
          usages[key] = usage;
          final spanKey = _referenceSpanKey(usage);
          if (reference.htmlAttributeQuote case final quote?) {
            htmlAttributeQuotes[spanKey] = quote;
          } else if (reference.xmlAttribute) {
            xmlAttributeSpans.add(spanKey);
          } else {
            markdownDestinationSpans.add(spanKey);
            if (reference.angleDestination) {
              markdownAngleDestinationSpans.add(spanKey);
            }
          }
        }
      }
    }

    final edits = <_TreeEdit>[];
    for (final context in contexts) {
      for (final sourceEntry in context.topicSources.entries) {
        final references =
            usages.values
                .where((usage) => p.equals(usage.filePath, sourceEntry.key))
                .toList()
              ..sort(
                (left, right) =>
                    right.span.startOffset.compareTo(left.span.startOffset),
              );
        if (references.isEmpty) continue;
        var updated = sourceEntry.value;
        var lastStart = updated.length + 1;
        for (final reference in references) {
          if (reference.span.startOffset < 0 ||
              reference.span.endOffset > updated.length ||
              reference.span.startOffset >= lastStart) {
            throw BusyMarkException(
              'writerside.topic-file.ambiguous-reference',
              args: {
                'reference': reference.value,
                'treePath': reference.filePath,
              },
            );
          }
          final expected = reference.sourceValue ?? reference.value;
          final actual = updated.substring(
            reference.span.startOffset,
            reference.span.endOffset,
          );
          if (actual != expected) {
            throw BusyMarkException(
              'writerside.topic-file.tree-changed',
              args: {'path': reference.filePath},
            );
          }
          var replacement = _renamedDocumentReference(
            reference.value,
            oldTopic: target.topic,
            newTopicFileName: newTopicFileName,
            newFileName: newFileName,
          );
          final spanKey = _referenceSpanKey(reference);
          if (htmlAttributeQuotes[spanKey] case final quote?) {
            replacement = _escapeHtmlAttributeValue(replacement, quote);
          } else if (xmlAttributeSpans.contains(spanKey)) {
            replacement = _escapeXmlAttributeValue(replacement);
          } else if (markdownDestinationSpans.contains(spanKey)) {
            replacement = _renamedMarkdownReferenceSource(
              decodedOriginal: reference.value,
              rawOriginal: expected,
              decodedReplacement: replacement,
              angleDestination: markdownAngleDestinationSpans.contains(spanKey),
            );
          }
          updated = updated.replaceRange(
            reference.span.startOffset,
            reference.span.endOffset,
            replacement,
          );
          lastStart = reference.span.startOffset;
        }
        if (updated != sourceEntry.value) {
          edits.add(
            _TreeEdit(
              anchor: context.anchor,
              path: sourceEntry.key,
              originalSource: sourceEntry.value,
              updatedSource: updated,
            ),
          );
        }
      }

      final moduleId = index.modulesById.entries
          .where(
            (entry) => p.equals(entry.value.rootPath, context.module.rootPath),
          )
          .map((entry) => entry.key)
          .single;
      for (final tree in context.trees) {
        var changed = false;
        final root = tree.document.rootElement;
        final startPage = root.getAttribute('start-page');
        if (startPage != null &&
            _projectReferenceTargetsTopic(
              index,
              target,
              startPage,
              moduleId: moduleId,
              filePath: tree.path,
            )) {
          root.setAttribute(
            'start-page',
            _renamedDocumentReference(
              startPage,
              oldTopic: target.topic,
              newTopicFileName: newTopicFileName,
              newFileName: newFileName,
            ),
          );
          changed = true;
        }
        for (final element in tree.document.findAllElements('toc-element')) {
          for (final attributeName in const ['topic', 'ref']) {
            final reference = element.getAttribute(attributeName);
            if (reference == null ||
                !_projectReferenceTargetsTopic(
                  index,
                  target,
                  reference,
                  moduleId: moduleId,
                  origin: element.getAttribute('origin'),
                  filePath: tree.path,
                )) {
              continue;
            }
            element.setAttribute(
              attributeName,
              _renamedDocumentReference(
                reference,
                oldTopic: target.topic,
                newTopicFileName: newTopicFileName,
                newFileName: newFileName,
              ),
            );
            changed = true;
          }
        }
        if (changed) {
          edits.add(
            _TreeEdit(
              anchor: context.anchor,
              path: tree.path,
              originalSource: tree.source,
              updatedSource: _xmlSource(tree.document),
            ),
          );
        }
      }
    }
    return edits;
  }

  ({WritersideReference reference, bool xmlAttribute})?
  _indexedWritableTopicReference(
    WritersideTopic topic,
    WritersideReference reference,
  ) {
    final source = topic.document.source;
    final span = reference.span;
    if (span.startOffset < 0 ||
        span.endOffset > source.length ||
        span.startOffset > span.endOffset) {
      return null;
    }
    if (topic.format == WritersideTopicFormat.markdown) {
      final isTypedAttribute = topic.document.elements.any((element) {
        final attributeName = switch (element.semanticKind) {
          WritersideSemanticKind.include => 'from',
          WritersideSemanticKind.link || WritersideSemanticKind.card => 'href',
          _ => null,
        };
        if (attributeName == null ||
            element.attributes[attributeName] != reference.value) {
          return false;
        }
        final attributeSpan = element.attributeSpans[attributeName];
        return attributeSpan != null && _sameSpan(attributeSpan, span);
      });
      if (!isTypedAttribute) return null;
    }
    return (
      reference: WritersideReference(
        value: reference.value,
        kind: reference.kind,
        moduleId: reference.moduleId,
        filePath: reference.filePath,
        span: span,
        origin: reference.origin,
        sourceValue: source.substring(span.startOffset, span.endOffset),
        scopeReference: reference.scopeReference,
        nullable: reference.nullable,
      ),
      xmlAttribute: true,
    );
  }

  _AuthoredMarkdownProjection _authoredMarkdownTopicReferences(
    WritersideTopic topic,
  ) {
    final protected = _markdownLiteralMask(topic);
    final definitions = _markdownReferenceDefinitions(topic, protected);
    final authored =
        <_AuthoredMarkdownTopicReference>[
          ..._markdownLinkOccurrences(topic, protected, definitions),
          ..._markdownHtmlLinkOccurrences(topic, protected),
        ]..sort(
          (left, right) =>
              left.occurrenceOffset.compareTo(right.occurrenceOffset),
        );
    final bound = <_AuthoredMarkdownTopicReference>[];
    final unbound = <_UnboundMarkdownTopicReference>[];
    final consumed = <int>{};
    final referenceOccurrenceValidity = <int, bool>{};
    final linkOrigins = _markdownLinkOriginsInParseOrder(topic);
    for (var linkIndex = 0; linkIndex < topic.links.length; linkIndex++) {
      final link = topic.links[linkIndex];
      int? selected;
      for (var index = 0; index < authored.length; index++) {
        if (consumed.contains(index)) continue;
        final candidate = authored[index];
        if (candidate.destination != link.destination) continue;
        final belongsToParsedLink =
            (candidate.occurrenceOffset >= link.span.startOffset &&
                candidate.occurrenceOffset < link.span.endOffset) ||
            (candidate.destinationSpan.startOffset >= link.span.startOffset &&
                candidate.destinationSpan.endOffset <= link.span.endOffset);
        if (!belongsToParsedLink) continue;
        if ((candidate.inlineMarkdownDestination || candidate.xmlAttribute) &&
            !_markdownDestinationBelongsToParsedLink(topic, link, candidate)) {
          continue;
        }
        if (candidate.referenceLabelSpan != null &&
            !(referenceOccurrenceValidity[index] ??=
                _referenceMarkdownOccurrenceBelongsToParsedLink(
                  topic,
                  candidate,
                ))) {
          continue;
        }
        selected = index;
        break;
      }
      if (selected != null) {
        consumed.add(selected);
        bound.add(authored[selected]);
      } else {
        unbound.add(
          _UnboundMarkdownTopicReference(
            link: link,
            origin: linkIndex < linkOrigins.length
                ? linkOrigins[linkIndex]
                : null,
          ),
        );
      }
    }
    return _AuthoredMarkdownProjection(
      references: List.unmodifiable(bound),
      unboundLinks: List.unmodifiable(unbound),
    );
  }

  List<String?> _markdownLinkOriginsInParseOrder(WritersideTopic topic) {
    final origins = <String?>[];

    void visitInline(BusyInline inline) {
      if (inline.kind == BusyInlineKind.link &&
          inline.destination?.trim().isNotEmpty == true) {
        final origin = inline.attributes['origin']?.trim();
        origins.add(origin?.isEmpty == true ? null : origin);
      }
      for (final child in inline.children) {
        visitInline(child);
      }
    }

    void visitBlock(BusyBlock block) {
      for (final inline in block.inlines) {
        visitInline(inline);
      }
      for (final child in block.children) {
        visitBlock(child);
      }
    }

    for (final block in topic.markdown?.busyDocument.blocks ?? const []) {
      visitBlock(block);
    }
    return origins;
  }

  bool _markdownDestinationBelongsToParsedLink(
    WritersideTopic topic,
    MarkdownLink link,
    _AuthoredMarkdownTopicReference candidate,
  ) {
    final source = topic.document.source;
    final contextStart = link.span.startOffset;
    final contextEnd = link.span.endOffset;
    final destinationStart = candidate.destinationSpan.startOffset;
    final destinationEnd = candidate.destinationSpan.endOffset;
    if (contextStart < 0 ||
        contextEnd > source.length ||
        contextStart >= contextEnd ||
        destinationStart < contextStart ||
        destinationEnd > contextEnd ||
        destinationStart >= destinationEnd) {
      return false;
    }

    var probe = 'busymark-rename-probe-$destinationStart.invalid';
    while (source.contains(probe)) {
      probe = 'x$probe';
    }
    final context = source.substring(contextStart, contextEnd);
    final probed = context.replaceRange(
      destinationStart - contextStart,
      destinationEnd - contextStart,
      probe,
    );
    final parsed = const MarkdownAstAdapter().parseInlineFragment(
      source: probed,
      mode: MarkdownMode.writersideMarkdown,
    );

    bool containsProbe(Iterable<BusyInline> inlines) {
      for (final inline in inlines) {
        if (inline.kind == BusyInlineKind.link && inline.destination == probe) {
          return true;
        }
        if (containsProbe(inline.children)) return true;
      }
      return false;
    }

    return containsProbe(parsed);
  }

  bool _referenceMarkdownOccurrenceBelongsToParsedLink(
    WritersideTopic topic,
    _AuthoredMarkdownTopicReference candidate,
  ) {
    final source = topic.document.source;
    final referenceLabelSpan = candidate.referenceLabelSpan;
    final definitionLabelSpan = candidate.definitionLabelSpan;
    if (referenceLabelSpan == null || definitionLabelSpan == null) {
      return false;
    }
    final spans = [
      referenceLabelSpan,
      definitionLabelSpan,
      candidate.destinationSpan,
    ];
    if (spans.any(
      (span) =>
          span.startOffset < 0 ||
          span.endOffset > source.length ||
          span.startOffset >= span.endOffset,
    )) {
      return false;
    }

    var probeLabel = 'busymark-rename-reference-${candidate.occurrenceOffset}';
    while (source.toLowerCase().contains(probeLabel.toLowerCase())) {
      probeLabel = 'x$probeLabel';
    }
    var probeDestination =
        'busymark-rename-destination-${candidate.occurrenceOffset}.invalid';
    while (source.contains(probeDestination) ||
        probeDestination == candidate.destination ||
        topic.links.any((link) => link.destination == probeDestination)) {
      probeDestination = 'x$probeDestination';
    }

    final replacements =
        <({SourceSpan span, String value})>[
          (span: referenceLabelSpan, value: probeLabel),
          (span: definitionLabelSpan, value: probeLabel),
          (span: candidate.destinationSpan, value: probeDestination),
        ]..sort(
          (left, right) =>
              right.span.startOffset.compareTo(left.span.startOffset),
        );
    var probed = source;
    for (final replacement in replacements) {
      probed = probed.replaceRange(
        replacement.span.startOffset,
        replacement.span.endOffset,
        replacement.value,
      );
    }
    final parsed = const MarkdownParser().parse(
      filePath: topic.filePath,
      source: probed,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    return parsed.links
            .where((link) => link.destination == probeDestination)
            .length ==
        1;
  }

  List<bool> _markdownLiteralMask(WritersideTopic topic) {
    final source = topic.document.source;
    final protected = List<bool>.filled(source.length, false);
    void protect(int start, int end) {
      final safeStart = start.clamp(0, source.length);
      final safeEnd = end.clamp(safeStart, source.length);
      for (var index = safeStart; index < safeEnd; index++) {
        protected[index] = true;
      }
    }

    for (final codeBlock in topic.markdown?.codeBlocks ?? const []) {
      protect(codeBlock.span.startOffset, codeBlock.span.endOffset);
    }
    for (final comment in RegExp(r'<!--[\s\S]*?(?:-->|$)').allMatches(source)) {
      protect(comment.start, comment.end);
    }
    for (var cursor = 0; cursor < source.length; cursor++) {
      if (protected[cursor] ||
          source[cursor] != '`' ||
          _isEscapedMarkdownCharacter(source, cursor)) {
        continue;
      }
      var delimiterLength = 1;
      while (cursor + delimiterLength < source.length &&
          source[cursor + delimiterLength] == '`') {
        delimiterLength++;
      }
      var closing = cursor + delimiterLength;
      while (closing < source.length) {
        if (!protected[closing] && source[closing] == '`') {
          var runLength = 1;
          while (closing + runLength < source.length &&
              source[closing + runLength] == '`') {
            runLength++;
          }
          if (runLength == delimiterLength) break;
          closing += runLength;
        } else {
          closing++;
        }
      }
      if (closing < source.length) {
        protect(cursor, closing + delimiterLength);
        cursor = closing + delimiterLength - 1;
      }
    }
    return protected;
  }

  Map<String, _MarkdownReferenceDefinition> _markdownReferenceDefinitions(
    WritersideTopic topic,
    List<bool> protected,
  ) {
    final source = topic.document.source;
    final definitions = <String, _MarkdownReferenceDefinition>{};
    final pattern = RegExp(
      r'''^([ \t]{0,3}\[([^\]\r\n]+)\]:[ \t]*(?:\r?\n[ \t]+)?)(?:<([^>\r\n]+)>|([^\s\r\n]+))''',
      multiLine: true,
    );
    for (final match in pattern.allMatches(source)) {
      if (_rangeIsProtected(protected, match.start, match.end)) continue;
      final rawDestination = match.group(3) ?? match.group(4)!;
      final definitionPrefix = match.group(1)!;
      final rawLabel = match.group(2)!;
      final definitionLabelStart =
          match.start + definitionPrefix.indexOf('[') + 1;
      final destinationStart =
          match.start +
          definitionPrefix.length +
          (match.group(3) == null ? 0 : 1);
      final definition = _MarkdownReferenceDefinition(
        destination: _decodeMarkdownDestination(rawDestination),
        rawDestination: rawDestination,
        labelSpan: SourceSpan.fromOffsets(
          filePath: topic.filePath,
          source: source,
          startOffset: definitionLabelStart,
          endOffset: definitionLabelStart + rawLabel.length,
        ),
        destinationSpan: SourceSpan.fromOffsets(
          filePath: topic.filePath,
          source: source,
          startOffset: destinationStart,
          endOffset: destinationStart + rawDestination.length,
        ),
        angleDestination: match.group(3) != null,
      );
      definitions.putIfAbsent(
        _normalizedMarkdownLabel(match.group(2)!),
        () => definition,
      );
      final lineEnd = source.indexOf('\n', match.end);
      final protectedEnd = lineEnd < 0 ? source.length : lineEnd;
      for (var index = match.start; index < protectedEnd; index++) {
        protected[index] = true;
      }
    }
    return definitions;
  }

  List<_AuthoredMarkdownTopicReference> _markdownLinkOccurrences(
    WritersideTopic topic,
    List<bool> protected,
    Map<String, _MarkdownReferenceDefinition> definitions,
  ) {
    final source = topic.document.source;
    final occurrences = <_AuthoredMarkdownTopicReference>[];
    var cursor = 0;
    while (cursor < source.length) {
      final labelStart = source.indexOf('[', cursor);
      if (labelStart < 0) break;
      cursor = labelStart + 1;
      if (protected[labelStart] ||
          _isEscapedMarkdownCharacter(source, labelStart) ||
          (labelStart > 0 &&
              source[labelStart - 1] == '!' &&
              !_isEscapedMarkdownCharacter(source, labelStart - 1))) {
        continue;
      }
      final labelEnd = _closingMarkdownBracket(source, labelStart, protected);
      if (labelEnd == null) continue;
      final label = source.substring(labelStart + 1, labelEnd);
      final afterLabel = labelEnd + 1;
      if (afterLabel < source.length && source[afterLabel] == '(') {
        final destination = _inlineMarkdownDestination(
          topic,
          labelStart,
          afterLabel,
          protected,
        );
        if (destination != null) {
          occurrences.add(
            _AuthoredMarkdownTopicReference(
              occurrenceOffset: labelStart,
              destination: destination.destination,
              rawDestination: destination.rawDestination,
              destinationSpan: destination.destinationSpan,
              angleDestination: destination.angleDestination,
              inlineMarkdownDestination: true,
            ),
          );
          cursor = destination.linkEndOffset;
        }
        continue;
      }

      String? referenceLabel;
      SourceSpan? referenceLabelSpan;
      var referenceEnd = afterLabel;
      if (afterLabel < source.length && source[afterLabel] == '[') {
        final closing = _closingMarkdownBracket(source, afterLabel, protected);
        if (closing == null) continue;
        final explicit = source.substring(afterLabel + 1, closing);
        referenceLabel = explicit.isEmpty ? label : explicit;
        referenceLabelSpan = SourceSpan.fromOffsets(
          filePath: topic.filePath,
          source: source,
          startOffset: explicit.isEmpty ? labelStart + 1 : afterLabel + 1,
          endOffset: explicit.isEmpty ? labelEnd : closing,
        );
        referenceEnd = closing + 1;
      } else {
        referenceLabel = label;
        referenceLabelSpan = SourceSpan.fromOffsets(
          filePath: topic.filePath,
          source: source,
          startOffset: labelStart + 1,
          endOffset: labelEnd,
        );
      }
      final definition = definitions[_normalizedMarkdownLabel(referenceLabel)];
      if (definition == null) continue;
      occurrences.add(
        _AuthoredMarkdownTopicReference(
          occurrenceOffset: labelStart,
          destination: definition.destination,
          rawDestination: definition.rawDestination,
          destinationSpan: definition.destinationSpan,
          angleDestination: definition.angleDestination,
          referenceLabelSpan: referenceLabelSpan,
          definitionLabelSpan: definition.labelSpan,
        ),
      );
      cursor = referenceEnd;
    }
    return occurrences;
  }

  List<_AuthoredMarkdownTopicReference> _markdownHtmlLinkOccurrences(
    WritersideTopic topic,
    List<bool> protected,
  ) {
    final source = topic.document.source;
    final occurrences = <_AuthoredMarkdownTopicReference>[];
    final tokenizer = HtmlTokenizer(
      source,
      generateSpans: true,
      attributeSpans: true,
    );
    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      if (token is! StartTagToken || token.name != 'a') continue;
      final tagSpan = token.span;
      if (tagSpan == null ||
          _rangeIsProtected(
            protected,
            tagSpan.start.offset,
            tagSpan.end.offset,
          )) {
        continue;
      }
      final attributes = token.attributeSpans;
      if (attributes == null) continue;
      final href = attributes
          .where((attribute) => attribute.name == 'href')
          .firstOrNull;
      final hrefStart = href?.startValue;
      final hrefEnd = href?.endValue;
      final destination = href?.value;
      if (href == null ||
          hrefStart == null ||
          hrefEnd == null ||
          hrefStart < 0 ||
          hrefEnd > source.length ||
          hrefStart >= hrefEnd ||
          destination == null ||
          destination.isEmpty) {
        continue;
      }
      final origin = token.data['origin']?.trim();
      final htmlAttributeQuote = switch (hrefStart > tagSpan.start.offset
          ? source[hrefStart - 1]
          : null) {
        '"' when hrefEnd < tagSpan.end.offset && source[hrefEnd] == '"' =>
          _HtmlAttributeQuote.doubleQuoted,
        "'" when hrefEnd < tagSpan.end.offset && source[hrefEnd] == "'" =>
          _HtmlAttributeQuote.singleQuoted,
        _ => _HtmlAttributeQuote.unquoted,
      };
      occurrences.add(
        _AuthoredMarkdownTopicReference(
          occurrenceOffset: tagSpan.start.offset,
          destination: destination,
          rawDestination: source.substring(hrefStart, hrefEnd),
          destinationSpan: SourceSpan.fromOffsets(
            filePath: topic.filePath,
            source: source,
            startOffset: hrefStart,
            endOffset: hrefEnd,
          ),
          origin: origin?.isEmpty == true ? null : origin,
          xmlAttribute: true,
          htmlAttributeQuote: htmlAttributeQuote,
        ),
      );
    }
    return occurrences;
  }

  _InlineMarkdownDestination? _inlineMarkdownDestination(
    WritersideTopic topic,
    int linkStart,
    int openingParenthesis,
    List<bool> protected,
  ) {
    final source = topic.document.source;
    var start = openingParenthesis + 1;
    while (start < source.length &&
        _isMarkdownWhitespace(source.codeUnitAt(start))) {
      start++;
    }
    if (start >= source.length || protected[start]) return null;
    var end = start;
    final angleDestination = source[start] == '<';
    if (angleDestination) {
      start++;
      end = start;
      while (end < source.length &&
          !protected[end] &&
          (source[end] != '>' || _isEscapedMarkdownCharacter(source, end))) {
        end++;
      }
      if (end >= source.length || protected[end]) return null;
    } else {
      var nestedParentheses = 0;
      while (end < source.length && !protected[end]) {
        final character = source[end];
        if (_isEscapedMarkdownCharacter(source, end)) {
          end++;
          continue;
        }
        if (character == '(') {
          nestedParentheses++;
        } else if (character == ')') {
          if (nestedParentheses == 0) break;
          nestedParentheses--;
        } else if (_isMarkdownWhitespace(source.codeUnitAt(end))) {
          break;
        }
        end++;
      }
    }
    if (end <= start) return null;
    final linkEnd = _inlineMarkdownLinkEnd(
      source,
      openingParenthesis,
      protected,
    );
    if (linkEnd == null) return null;
    final rawDestination = source.substring(start, end);
    final decodedDestination = _decodeMarkdownDestination(rawDestination);
    final parsed = const MarkdownAstAdapter().parseInlineFragment(
      source: source.substring(linkStart, linkEnd),
      mode: MarkdownMode.writersideMarkdown,
    );
    if (parsed.length != 1 ||
        parsed.single.kind != BusyInlineKind.link ||
        parsed.single.destination != decodedDestination) {
      return null;
    }
    return _InlineMarkdownDestination(
      destination: decodedDestination,
      rawDestination: rawDestination,
      destinationSpan: SourceSpan.fromOffsets(
        filePath: topic.filePath,
        source: source,
        startOffset: start,
        endOffset: end,
      ),
      angleDestination: angleDestination,
      linkEndOffset: linkEnd,
    );
  }

  int? _inlineMarkdownLinkEnd(
    String source,
    int openingParenthesis,
    List<bool> protected,
  ) {
    var nestedParentheses = 0;
    String? quote;
    for (var index = openingParenthesis + 1; index < source.length; index++) {
      if (protected[index] || _isEscapedMarkdownCharacter(source, index)) {
        continue;
      }
      final character = source[index];
      if (quote != null) {
        if (character == quote) quote = null;
        continue;
      }
      if (character == '"' || character == "'") {
        quote = character;
      } else if (character == '(') {
        nestedParentheses++;
      } else if (character == ')') {
        if (nestedParentheses == 0) return index + 1;
        nestedParentheses--;
      }
    }
    return null;
  }

  int? _closingMarkdownBracket(
    String source,
    int opening,
    List<bool> protected,
  ) {
    var depth = 1;
    for (var index = opening + 1; index < source.length; index++) {
      if (protected[index]) continue;
      if (_isEscapedMarkdownCharacter(source, index)) continue;
      if (source[index] == '[') {
        depth++;
      } else if (source[index] == ']') {
        depth--;
        if (depth == 0) return index;
      }
    }
    return null;
  }

  bool _rangeIsProtected(List<bool> protected, int start, int end) {
    for (var index = start; index < end; index++) {
      if (protected[index]) return true;
    }
    return false;
  }

  String _normalizedMarkdownLabel(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _decodeMarkdownDestination(String value) {
    var decoded = value.replaceAllMapped(
      RegExp(r'''\\([!"#\$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~])'''),
      (match) => match.group(1)!,
    );
    try {
      decoded = XmlDocument.parse(
        '<value>$decoded</value>',
      ).rootElement.innerText;
    } on XmlParserException {
      // The Markdown parser remains authoritative for unusual destinations;
      // binding below discards source candidates that do not match it.
    }
    return decoded;
  }

  String _referenceSpanKey(WritersideReference reference) =>
      '${normalizePath(reference.filePath)}:'
      '${reference.span.startOffset}:${reference.span.endOffset}';

  String _escapeXmlAttributeValue(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _escapeHtmlAttributeValue(String value, _HtmlAttributeQuote quote) {
    if (quote != _HtmlAttributeQuote.unquoted) {
      return _escapeXmlAttributeValue(value);
    }
    final escaped = StringBuffer();
    for (final rune in value.runes) {
      escaped.write(switch (rune) {
        0x09 => '&#9;',
        0x0A => '&#10;',
        0x0C => '&#12;',
        0x0D => '&#13;',
        0x20 => '&#32;',
        0x22 => '&quot;',
        0x26 => '&amp;',
        0x27 => '&#39;',
        0x3C => '&lt;',
        0x3D => '&#61;',
        0x3E => '&gt;',
        0x60 => '&#96;',
        _ => String.fromCharCode(rune),
      });
    }
    return escaped.toString();
  }

  String _renamedMarkdownReferenceSource({
    required String decodedOriginal,
    required String rawOriginal,
    required String decodedReplacement,
    required bool angleDestination,
  }) {
    if (decodedReplacement == decodedOriginal) return rawOriginal;
    final decodedHash = decodedOriginal.indexOf('#');
    final decodedPath = decodedHash < 0
        ? decodedOriginal
        : decodedOriginal.substring(0, decodedHash);
    final decodedSuffix = decodedHash < 0
        ? ''
        : decodedOriginal.substring(decodedHash);
    final replacementHash = decodedReplacement.indexOf('#');
    final replacementPath = replacementHash < 0
        ? decodedReplacement
        : decodedReplacement.substring(0, replacementHash);
    final replacementSuffix = replacementHash < 0
        ? ''
        : decodedReplacement.substring(replacementHash);
    final rawHash = rawOriginal.indexOf('#');
    final rawPath = rawHash < 0
        ? rawOriginal
        : rawOriginal.substring(0, rawHash);
    final rawSuffix = rawHash < 0 ? '' : rawOriginal.substring(rawHash);

    final decodedSlash = decodedPath.lastIndexOf('/');
    final replacementSlash = replacementPath.lastIndexOf('/');
    final rawSlash = rawPath.lastIndexOf('/');
    final decodedPrefix = decodedSlash < 0
        ? ''
        : decodedPath.substring(0, decodedSlash + 1);
    final replacementPrefix = replacementSlash < 0
        ? ''
        : replacementPath.substring(0, replacementSlash + 1);
    final rawPrefix = rawSlash < 0 ? '' : rawPath.substring(0, rawSlash + 1);
    final canPreserveAuthoredPrefix =
        decodedPrefix == replacementPrefix &&
        _decodeMarkdownDestination(rawPrefix) == decodedPrefix;
    final canPreserveAuthoredSuffix =
        decodedSuffix == replacementSuffix &&
        _decodeMarkdownDestination(rawSuffix) == decodedSuffix;
    final replacementName = replacementSlash < 0
        ? replacementPath
        : replacementPath.substring(replacementSlash + 1);
    return '${canPreserveAuthoredPrefix ? rawPrefix : _escapeMarkdownDestination(replacementPrefix, angleDestination: angleDestination)}'
        '${_escapeMarkdownDestination(replacementName, angleDestination: angleDestination)}'
        '${canPreserveAuthoredSuffix ? rawSuffix : _escapeMarkdownDestination(replacementSuffix, angleDestination: angleDestination)}';
  }

  String _escapeMarkdownDestination(
    String value, {
    required bool angleDestination,
  }) {
    final result = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final escape =
          character == '\\' ||
          (angleDestination
              ? character == '>'
              : character == '(' || character == ')');
      if (escape) result.write('\\');
      result.write(character);
    }
    return '$result';
  }

  void _validateGeneratedXmlRenameSources(
    List<_ReferenceModuleContext> contexts, {
    required _MutationContext target,
    required String targetSource,
    required List<_TreeEdit> publishedEdits,
  }) {
    if (target.topic.format == WritersideTopicFormat.xml) {
      _validateGeneratedXmlTopic(target.topicPath, targetSource);
    }
    final xmlTopicPaths = <String>{
      for (final context in contexts)
        for (final topic in context.module.topics)
          if (topic.format == WritersideTopicFormat.xml)
            normalizePath(topic.filePath),
    };
    for (final edit in publishedEdits) {
      if (_isTreePath(edit.path)) {
        _validateGeneratedTree(edit.path, edit.updatedSource);
      } else if (xmlTopicPaths.contains(normalizePath(edit.path))) {
        _validateGeneratedXmlTopic(edit.path, edit.updatedSource);
      }
    }
  }

  void _validateGeneratedXmlTopic(String path, String source) {
    try {
      final document = XmlDocument.parse(source);
      if (document.rootElement.name.local != 'topic') {
        throw const FormatException('Expected a topic root element.');
      }
    } on Object catch (error) {
      throw BusyMarkException(
        'writerside.topic-file.topic-invalid',
        args: {'path': path, 'error': '$error'},
      );
    }
  }

  void _validateGeneratedTree(String path, String source) {
    try {
      final document = XmlDocument.parse(source);
      if (document.rootElement.name.local != 'instance-profile') {
        throw const FormatException(
          'Expected an instance-profile root element.',
        );
      }
    } on Object catch (error) {
      throw BusyMarkException(
        'writerside.topic-file.tree-invalid',
        args: {'path': path, 'error': '$error'},
      );
    }
  }

  bool _sameSpan(SourceSpan left, SourceSpan right) =>
      left.startOffset == right.startOffset &&
      left.endOffset == right.endOffset;

  bool _isEscapedMarkdownCharacter(String source, int offset) {
    var slashCount = 0;
    for (var index = offset - 1; index >= 0 && source[index] == '\\'; index--) {
      slashCount++;
    }
    return slashCount.isOdd;
  }

  bool _isMarkdownWhitespace(int codeUnit) =>
      codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d;

  bool _projectReferenceTargetsTopic(
    WritersideProjectIndex index,
    _MutationContext target,
    String reference, {
    required String moduleId,
    required String filePath,
    String? origin,
  }) {
    return index
        .definitions(
          reference.split('#').first,
          moduleId: moduleId,
          origin: origin,
          kind: WritersideSymbolKind.topic,
          filePath: filePath,
        )
        .any((symbol) => p.equals(symbol.filePath, target.topicPath));
  }

  String _renamedDocumentReference(
    String reference, {
    required WritersideTopic oldTopic,
    required String newTopicFileName,
    required String newFileName,
  }) {
    final hash = reference.indexOf('#');
    final pathPart = hash < 0 ? reference : reference.substring(0, hash);
    final suffix = hash < 0 ? '' : reference.substring(hash);
    if (pathPart.isEmpty) return reference;
    final normalized = _normalizedReference(pathPart);
    final directory = p.dirname(normalized);
    final oldId = oldTopic.id;
    final usesId =
        p.extension(normalized).isEmpty && p.basename(normalized) == oldId;
    if (usesId &&
        oldId !=
            p.basenameWithoutExtension(
              _normalizedReference(oldTopic.fileName),
            )) {
      return reference;
    }
    final replacementName = usesId
        ? p.basenameWithoutExtension(newFileName)
        : newFileName;
    if (normalized == _normalizedReference(oldTopic.fileName)) {
      return '$newTopicFileName$suffix';
    }
    final replacement = directory == '.'
        ? replacementName
        : p.join(directory, replacementName).replaceAll(r'\', '/');
    return '$replacement$suffix';
  }

  Future<_DeleteTreeMutation> _deleteTreeEdits(_MutationContext context) async {
    for (final tree in context.trees) {
      final startPage = tree.document.rootElement.getAttribute('start-page');
      if (startPage != null &&
          _referenceTargetsTopic(context, startPage, tree.path)) {
        throw BusyMarkException(
          'writerside.topic-file.is-start-page',
          args: {'topic': startPage, 'treePath': tree.path},
        );
      }
    }

    final edits = <_TreeEdit>[];
    var removedTocEntries = 0;
    for (final tree in context.trees) {
      final removed = _removeTopicTocElements(
        context,
        tree.document.rootElement,
        tree.path,
      );
      if (removed == 0) {
        continue;
      }
      removedTocEntries += removed;
      edits.add(
        _TreeEdit(
          path: tree.path,
          originalSource: tree.source,
          updatedSource: _xmlSource(tree.document),
        ),
      );
    }
    return _DeleteTreeMutation(
      edits: edits,
      removedTocEntries: removedTocEntries,
    );
  }

  int _removeTopicTocElements(
    _MutationContext context,
    XmlElement parent,
    String treePath,
  ) {
    var removed = 0;
    final children = parent.childElements
        .where((element) => element.name.local == 'toc-element')
        .toList();
    for (final child in children) {
      removed += _removeTopicTocElements(context, child, treePath);
      final reference = child.getAttribute('topic');
      if (reference == null ||
          !_referenceTargetsTopic(context, reference, treePath)) {
        continue;
      }
      final index = parent.children.indexOf(child);
      final promoted = child.childElements
          .where((element) => element.name.local == 'toc-element')
          .map((element) => element.copy())
          .toList();
      parent.children.removeAt(index);
      parent.children.insertAll(index, promoted);
      removed += 1;
    }
    return removed;
  }

  bool _referenceTargetsTopic(
    _MutationContext context,
    String reference,
    String treePath,
  ) {
    final normalizedReference = _normalizedReference(reference);
    var matches = context.module.topics
        .where(
          (candidate) =>
              _normalizedReference(candidate.fileName) == normalizedReference,
        )
        .toList();
    if (matches.isEmpty) {
      if (p.dirname(normalizedReference) != '.') {
        return false;
      }
      matches = context.module.topics
          .where(
            (candidate) =>
                p.basename(_normalizedReference(candidate.fileName)) ==
                normalizedReference,
          )
          .toList();
    }
    final targetMatches = matches
        .where(
          (candidate) =>
              p.equals(normalizePath(candidate.filePath), context.topicPath),
        )
        .length;
    if (targetMatches == 0) {
      return false;
    }
    if (matches.length != 1 || targetMatches != 1) {
      throw BusyMarkException(
        'writerside.topic-file.ambiguous-reference',
        args: {'reference': reference, 'treePath': treePath},
      );
    }
    return true;
  }

  _RenamedTopicSource _renamedTopicSource({
    required String path,
    required String source,
    required String newFileName,
  }) {
    if (p.extension(path).toLowerCase() != '.topic') {
      return _RenamedTopicSource(source: source, updatedXmlTopicId: false);
    }
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      throw BusyMarkException(
        'writerside.topic-file.topic-invalid',
        args: {'path': path, 'error': '$error'},
      );
    }
    final root = document.rootElement;
    if (root.name.local != 'topic') {
      throw BusyMarkException(
        'writerside.topic-file.topic-invalid',
        args: {'path': path},
      );
    }
    final oldId = p.basenameWithoutExtension(path);
    final currentId = root.getAttribute('id');
    if (currentId == null || currentId.isEmpty) {
      throw BusyMarkException(
        'writerside.topic-file.missing-root-id',
        args: {'path': path},
      );
    }
    if (currentId != oldId) {
      throw BusyMarkException(
        'writerside.topic-file.root-id-mismatch',
        args: {'path': path, 'id': currentId, 'expectedId': oldId},
      );
    }
    root.setAttribute('id', p.basenameWithoutExtension(newFileName));
    return _RenamedTopicSource(
      source: _xmlSource(document),
      updatedXmlTopicId: true,
    );
  }

  Future<void> _applyTreeEdits(
    CanonicalPathAnchor anchor,
    List<_TreeEdit> edits, {
    required List<_TreeEdit> applied,
  }) async {
    for (final edit in edits) {
      await _replaceFileAtomically(
        edit.anchor ?? anchor,
        edit.path,
        edit.updatedSource,
        expectedCurrentSource: edit.originalSource,
      );
      applied.add(edit);
    }
  }

  Future<bool> _rollbackTreeEdits(
    CanonicalPathAnchor anchor,
    List<_TreeEdit> edits,
  ) async {
    var restored = true;
    for (final edit in edits.reversed) {
      try {
        await _replaceFileAtomically(
          edit.anchor ?? anchor,
          edit.path,
          edit.originalSource,
          expectedCurrentSource: edit.updatedSource,
        );
      } on Object {
        // Best effort: never overwrite a tree changed by another writer.
        restored = false;
      }
    }
    return restored;
  }

  Future<void> _replaceFileAtomically(
    CanonicalPathAnchor anchor,
    String path,
    String source, {
    required String expectedCurrentSource,
  }) async {
    final resolution = await _resolvePath(anchor, path, allowRoot: false);
    if (resolution.type != FileSystemEntityType.file ||
        await File(resolution.path).readAsString() != expectedCurrentSource) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': resolution.path},
      );
    }
    final temporary = await _newTemporaryFile(anchor, resolution.path);
    try {
      await temporary.writeAsString(source, flush: true);
      final checked = await _resolvePath(anchor, path, allowRoot: false);
      if (checked.type != FileSystemEntityType.file ||
          await File(checked.path).readAsString() != expectedCurrentSource) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': checked.path},
        );
      }
      await _copyFileMode(await File(checked.path).stat(), temporary);
      await _beforeTreePublish?.call(checked.path);
      final publishTarget = await _resolvePath(anchor, path, allowRoot: false);
      if (publishTarget.type != FileSystemEntityType.file ||
          await File(publishTarget.path).readAsString() !=
              expectedCurrentSource) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': publishTarget.path},
        );
      }
      await temporary.rename(publishTarget.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<File> _newTemporaryFile(
    CanonicalPathAnchor anchor,
    String targetPath,
  ) async {
    for (var attempt = 0; attempt < 100; attempt += 1) {
      final name =
          '.${p.basename(targetPath)}.busymark-topic-edit-'
          '$pid-${DateTime.now().microsecondsSinceEpoch}-$attempt';
      final candidatePath = p.join(p.dirname(targetPath), name);
      final resolution = await _resolvePath(
        anchor,
        candidatePath,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.notFound) {
        continue;
      }
      try {
        return await File(resolution.path).create(exclusive: true);
      } on FileSystemException {
        continue;
      }
    }
    throw BusyMarkException(
      'writerside.topic-file.temporary-file-failed',
      args: {'path': targetPath},
    );
  }

  Future<void> _writeNewFile(
    CanonicalPathAnchor anchor,
    String path,
    String source, {
    required FileStat sourceStat,
  }) async {
    final resolution = await _resolvePath(anchor, path, allowRoot: false);
    if (resolution.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.topic-file.target-exists',
        args: {'path': resolution.path},
      );
    }
    final file = File(resolution.path);
    var createdByThisOperation = false;
    try {
      await _beforeNewFileCreate?.call(file.path);
      await file.create(exclusive: true);
      createdByThisOperation = true;
      final created = await _resolvePath(anchor, file.path, allowRoot: false);
      if (created.type != FileSystemEntityType.file) {
        throw BusyMarkException(
          'writerside.topic-file.target-unsafe',
          args: {'path': created.path},
        );
      }
      await _copyFileMode(sourceStat, File(created.path));
      await File(created.path).writeAsString(source, flush: true);
    } on Object {
      if (createdByThisOperation) {
        await _deleteCreatedFileBestEffort(anchor, file.path, source);
      }
      rethrow;
    }
  }

  Future<void> _copyFileMode(FileStat sourceStat, File target) async {
    if (Platform.isWindows) {
      return;
    }
    final mode = (sourceStat.mode & 0xfff).toRadixString(8);
    final result = await Process.run('chmod', [mode, target.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Failed to apply file mode $mode: ${result.stderr}',
        target.path,
      );
    }
  }

  Future<void> _ensureTreesAtExpectedSources(
    _MutationContext context,
    List<_TreeEdit> edits,
  ) async {
    final updatedSources = {
      for (final edit in edits) edit.path: edit.updatedSource,
    };
    for (final tree in context.trees) {
      final expectedSource = updatedSources[tree.path] ?? tree.source;
      final resolution = await _resolvePath(
        context.anchor,
        tree.path,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.file ||
          await File(resolution.path).readAsString() != expectedSource) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': resolution.path},
        );
      }
    }
  }

  Future<void> _ensureConfigurationUnchanged(_MutationContext context) async {
    final current = await _configurationSources(context.module.rootPath);
    if (!_sameStringMap(current, context.configurationSources)) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': context.module.config.filePath},
      );
    }
  }

  Future<void> _ensureTopicSourcesUnchanged(
    _MutationContext context, {
    Map<String, String> additionalSources = const {},
  }) async {
    final expected = <String, String>{
      ...context.topicSources,
      for (final entry in additionalSources.entries)
        normalizePath(entry.key): entry.value,
    };
    final current = await _topicSources(context.anchor, context.module);
    if (!_sameStringMap(current, expected)) {
      throw BusyMarkException(
        'writerside.topic-file.topic-inventory-changed',
        args: {'path': context.module.rootPath},
      );
    }
  }

  Future<void> _ensureReferenceContextsUnchanged(
    List<_ReferenceModuleContext> contexts,
    List<_TreeEdit> edits, {
    required String targetPath,
    required String targetSource,
    required String targetModuleRoot,
  }) async {
    final updatedSources = {
      for (final edit in edits) normalizePath(edit.path): edit.updatedSource,
    };
    for (final context in contexts) {
      final configuration = await _configurationSources(
        context.module.rootPath,
      );
      if (!_sameStringMap(configuration, context.configurationSources)) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': context.module.config.filePath},
        );
      }
      for (final tree in context.trees) {
        final expected = updatedSources[tree.path] ?? tree.source;
        final resolved = await _resolvePath(
          context.anchor,
          tree.path,
          allowRoot: false,
        );
        if (resolved.type != FileSystemEntityType.file ||
            await File(resolved.path).readAsString() != expected) {
          throw BusyMarkException(
            'writerside.topic-file.tree-changed',
            args: {'path': resolved.path},
          );
        }
      }
      final expectedTopics = <String, String>{
        ...context.topicSources,
        for (final entry in updatedSources.entries)
          if (context.topicSources.containsKey(entry.key))
            entry.key: entry.value,
        if (p.equals(context.module.rootPath, targetModuleRoot))
          normalizePath(targetPath): targetSource,
      };
      final currentTopics = await _topicSources(context.anchor, context.module);
      if (!_sameStringMap(currentTopics, expectedTopics)) {
        throw BusyMarkException(
          'writerside.topic-file.topic-inventory-changed',
          args: {'path': context.module.rootPath},
        );
      }
    }
  }

  Future<void> _ensurePreparedPlanUnchanged(
    WritersideTopicRenamePlan plan,
  ) async {
    final prepared = plan._prepared;
    for (final context in prepared.referenceContexts) {
      final configuration = await _configurationSources(
        context.module.rootPath,
      );
      if (!_sameStringMap(configuration, context.configurationSources)) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': context.module.config.filePath},
        );
      }
      for (final tree in context.trees) {
        final resolved = await _resolvePath(
          context.anchor,
          tree.path,
          allowRoot: false,
        );
        if (resolved.type != FileSystemEntityType.file ||
            await File(resolved.path).readAsString() != tree.source) {
          throw BusyMarkException(
            'writerside.topic-file.tree-changed',
            args: {'path': tree.path},
          );
        }
      }
      final currentTopics = await _topicSources(context.anchor, context.module);
      if (!_sameStringMap(currentTopics, context.topicSources)) {
        throw BusyMarkException(
          'writerside.topic-file.topic-inventory-changed',
          args: {'path': context.module.rootPath},
        );
      }
    }
    final destination = await _resolvePath(
      prepared.target.anchor,
      plan.newTopicPath,
      allowRoot: false,
    );
    if (destination.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.topic-file.target-exists',
        args: {'path': destination.path},
      );
    }
  }

  Future<bool> _renameTargetIsSafeToCleanUp(
    _MutationContext context, {
    required String targetPath,
    required String targetSource,
  }) async {
    try {
      await _ensureConfigurationUnchanged(context);
      await _ensureTreesAtExpectedSources(context, const []);
      await _ensureTopicSourcesUnchanged(
        context,
        additionalSources: {targetPath: targetSource},
      );
      return true;
    } on Object {
      // A concurrent edit may now reference the new path. Retaining a harmless
      // duplicate is safer than deleting a file that has become reachable.
      return false;
    }
  }

  Future<void> _deleteUnchangedTopicSource(_MutationContext context) async {
    final resolution = await _resolvePath(
      context.anchor,
      context.topicPath,
      allowRoot: false,
    );
    if (resolution.type != FileSystemEntityType.file ||
        await File(resolution.path).readAsString() != context.topicSource) {
      throw BusyMarkException(
        'writerside.topic-file.source-changed',
        args: {'path': resolution.path},
      );
    }
    await File(resolution.path).delete();
  }

  Future<void> _deleteCreatedFileBestEffort(
    CanonicalPathAnchor anchor,
    String path,
    String expectedSource,
  ) async {
    try {
      final resolution = await _resolvePath(anchor, path, allowRoot: false);
      if (resolution.type == FileSystemEntityType.file &&
          await File(resolution.path).readAsString() == expectedSource) {
        await File(resolution.path).delete();
      }
    } on Object {
      // Best effort cleanup after a failed multi-file mutation.
    }
  }

  Future<AnchoredPathResolution> _resolvePath(
    CanonicalPathAnchor anchor,
    String path, {
    required bool allowRoot,
  }) async {
    try {
      return await resolveAnchoredPath(
        anchor,
        normalizePath(path),
        allowRoot: allowRoot,
      );
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic-file.path-unsafe',
        args: {'path': error.path},
      );
    }
  }

  String _safeRenamedFileName(String value, {required String oldPath}) {
    final oldExtension = p.extension(oldPath).toLowerCase();
    return validateWritersideTopicFileName(
      value,
      requiredExtension: oldExtension,
    );
  }

  String _renamedTopicFileName(String oldFileName, String newFileName) {
    final directory = p.dirname(_normalizedReference(oldFileName));
    return directory == '.'
        ? newFileName
        : p.join(directory, newFileName).replaceAll(r'\', '/');
  }

  String _normalizedReference(String value) {
    return p.normalize(value.trim()).replaceAll(r'\', '/');
  }

  String _xmlSource(XmlDocument document) {
    return '${document.toXmlString(pretty: true, indent: '  ')}\n';
  }
}

class _AuthoredMarkdownTopicReference {
  const _AuthoredMarkdownTopicReference({
    required this.occurrenceOffset,
    required this.destination,
    required this.rawDestination,
    required this.destinationSpan,
    this.origin,
    this.xmlAttribute = false,
    this.htmlAttributeQuote,
    this.angleDestination = false,
    this.inlineMarkdownDestination = false,
    this.referenceLabelSpan,
    this.definitionLabelSpan,
  });

  final int occurrenceOffset;
  final String destination;
  final String rawDestination;
  final SourceSpan destinationSpan;
  final String? origin;
  final bool xmlAttribute;
  final _HtmlAttributeQuote? htmlAttributeQuote;
  final bool angleDestination;
  final bool inlineMarkdownDestination;
  final SourceSpan? referenceLabelSpan;
  final SourceSpan? definitionLabelSpan;
}

enum _HtmlAttributeQuote { doubleQuoted, singleQuoted, unquoted }

class _AuthoredMarkdownProjection {
  const _AuthoredMarkdownProjection({
    required this.references,
    required this.unboundLinks,
  });

  final List<_AuthoredMarkdownTopicReference> references;
  final List<_UnboundMarkdownTopicReference> unboundLinks;
}

class _UnboundMarkdownTopicReference {
  const _UnboundMarkdownTopicReference({required this.link, this.origin});

  final MarkdownLink link;
  final String? origin;

  String get destination => link.destination;
  SourceSpan get span => link.span;
}

class _MarkdownReferenceDefinition {
  const _MarkdownReferenceDefinition({
    required this.destination,
    required this.rawDestination,
    required this.destinationSpan,
    this.labelSpan,
    this.angleDestination = false,
  });

  final String destination;
  final String rawDestination;
  final SourceSpan? labelSpan;
  final SourceSpan destinationSpan;
  final bool angleDestination;
}

class _InlineMarkdownDestination extends _MarkdownReferenceDefinition {
  const _InlineMarkdownDestination({
    required super.destination,
    required super.rawDestination,
    required super.destinationSpan,
    required super.angleDestination,
    required this.linkEndOffset,
  });

  final int linkEndOffset;
}

class _MutationContext {
  const _MutationContext({
    required this.anchor,
    required this.module,
    required this.topic,
    required this.topicPath,
    required this.topicSource,
    required this.topicStat,
    required this.configurationSources,
    required this.topicSources,
    required this.trees,
  });

  final CanonicalPathAnchor anchor;
  final WritersideModule module;
  final WritersideTopic topic;
  final String topicPath;
  final String topicSource;
  final FileStat topicStat;
  final Map<String, String?> configurationSources;
  final Map<String, String> topicSources;
  final List<_LoadedTree> trees;
}

class _CurrentModuleSnapshot {
  const _CurrentModuleSnapshot({
    required this.module,
    required this.topic,
    required this.configurationSources,
    required this.topicSources,
  });

  final WritersideModule module;
  final WritersideTopic topic;
  final Map<String, String?> configurationSources;
  final Map<String, String> topicSources;
}

class _ReferenceModuleContext {
  const _ReferenceModuleContext({
    required this.anchor,
    required this.module,
    required this.configurationSources,
    required this.topicSources,
    required this.trees,
  });

  factory _ReferenceModuleContext.fromMutation(_MutationContext context) {
    return _ReferenceModuleContext(
      anchor: context.anchor,
      module: context.module,
      configurationSources: context.configurationSources,
      topicSources: context.topicSources,
      trees: context.trees,
    );
  }

  final CanonicalPathAnchor anchor;
  final WritersideModule module;
  final Map<String, String?> configurationSources;
  final Map<String, String> topicSources;
  final List<_LoadedTree> trees;
}

class _LoadedTree {
  const _LoadedTree({
    required this.path,
    required this.source,
    required this.document,
  });

  final String path;
  final String source;
  final XmlDocument document;
}

class _TreeEdit {
  const _TreeEdit({
    this.anchor,
    required this.path,
    required this.originalSource,
    required this.updatedSource,
  });

  final CanonicalPathAnchor? anchor;
  final String path;
  final String originalSource;
  final String updatedSource;
}

class _DeleteTreeMutation {
  const _DeleteTreeMutation({
    required this.edits,
    required this.removedTocEntries,
  });

  final List<_TreeEdit> edits;
  final int removedTocEntries;
}

class _RenamedTopicSource {
  const _RenamedTopicSource({
    required this.source,
    required this.updatedXmlTopicId,
  });

  final String source;
  final bool updatedXmlTopicId;
}

class _PreparedTopicRename {
  const _PreparedTopicRename({
    required this.target,
    required this.referenceContexts,
    required this.targetSource,
    required this.publishedEdits,
  });

  final _MutationContext target;
  final List<_ReferenceModuleContext> referenceContexts;
  final String targetSource;
  final List<_TreeEdit> publishedEdits;
}

bool _sameStringMap(Map<String, String?> first, Map<String, String?> second) {
  if (first.length != second.length) {
    return false;
  }
  for (final entry in first.entries) {
    if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _isTreePath(String path) => p.extension(path).toLowerCase() == '.tree';
