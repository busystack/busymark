import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/path_utils.dart';
import 'writerside_model.dart';
import 'writerside_module_service.dart';

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

/// Mutates a resolved Writerside topic file and all configured instance trees.
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
  }) async {
    final snapshot = await _currentModuleSnapshot(module, topic);
    final context = await _mutationContext(snapshot);
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
      return WritersideTopicFileRenameResult(
        oldTopicPath: context.topicPath,
        newTopicPath: context.topicPath,
        oldTopicFileName: context.topic.fileName,
        newTopicFileName: context.topic.fileName,
        updatedTreePaths: const [],
        updatedXmlTopicId: false,
      );
    }

    await _validateRenameTarget(
      context,
      targetPath: targetPath,
      newTopicFileName: newTopicFileName,
      newFileName: safeFileName,
    );
    final treeEdits = await _renameTreeEdits(
      context,
      newTopicFileName: newTopicFileName,
      newFileName: safeFileName,
    );
    final topicEdit = _renamedTopicSource(
      path: context.topicPath,
      source: context.topicSource,
      newFileName: safeFileName,
    );

    await _writeNewFile(
      context.anchor,
      targetPath,
      topicEdit.source,
      sourceStat: context.topicStat,
    );
    final appliedTreeEdits = <_TreeEdit>[];
    try {
      await _applyTreeEdits(
        context.anchor,
        treeEdits,
        applied: appliedTreeEdits,
      );
      await _ensureTreesAtExpectedSources(context, treeEdits);
      await _ensureConfigurationUnchanged(context);
      await _ensureTopicSourcesUnchanged(
        context,
        additionalSources: {targetPath: topicEdit.source},
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
            targetPath: targetPath,
            targetSource: topicEdit.source,
          );
      if (safeToCleanUp) {
        await _deleteCreatedFileBestEffort(
          context.anchor,
          targetPath,
          topicEdit.source,
        );
      }
      rethrow;
    }

    return WritersideTopicFileRenameResult(
      oldTopicPath: context.topicPath,
      newTopicPath: targetPath,
      oldTopicFileName: context.topic.fileName,
      newTopicFileName: newTopicFileName,
      updatedTreePaths: List.unmodifiable([
        for (final edit in treeEdits) edit.path,
      ]),
      updatedXmlTopicId: topicEdit.updatedXmlTopicId,
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

  Future<List<_TreeEdit>> _renameTreeEdits(
    _MutationContext context, {
    required String newTopicFileName,
    required String newFileName,
  }) async {
    final edits = <_TreeEdit>[];
    for (final tree in context.trees) {
      var changed = false;
      final root = tree.document.rootElement;
      final startPage = root.getAttribute('start-page');
      if (startPage != null &&
          _referenceTargetsTopic(context, startPage, tree.path)) {
        root.setAttribute(
          'start-page',
          _renamedReference(
            startPage,
            oldTopicFileName: context.topic.fileName,
            newTopicFileName: newTopicFileName,
            newFileName: newFileName,
          ),
        );
        changed = true;
      }
      for (final element in tree.document.findAllElements('toc-element')) {
        final reference = element.getAttribute('topic');
        if (reference == null ||
            !_referenceTargetsTopic(context, reference, tree.path)) {
          continue;
        }
        element.setAttribute(
          'topic',
          _renamedReference(
            reference,
            oldTopicFileName: context.topic.fileName,
            newTopicFileName: newTopicFileName,
            newFileName: newFileName,
          ),
        );
        changed = true;
      }
      if (changed) {
        edits.add(
          _TreeEdit(
            path: tree.path,
            originalSource: tree.source,
            updatedSource: _xmlSource(tree.document),
          ),
        );
      }
    }
    return edits;
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
    if (root.getAttribute('id') != oldId) {
      return _RenamedTopicSource(source: source, updatedXmlTopicId: false);
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
        anchor,
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
          anchor,
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
    final fileName = value.trim();
    if (fileName.isEmpty ||
        fileName == '.' ||
        fileName == '..' ||
        p.isAbsolute(fileName) ||
        fileName.contains('/') ||
        fileName.contains(r'\') ||
        fileName.contains('..')) {
      throw const BusyMarkException('writerside.topic-file.file-name-unsafe');
    }
    final oldExtension = p.extension(oldPath).toLowerCase();
    if (!{'.md', '.markdown', '.topic'}.contains(oldExtension) ||
        p.extension(fileName).toLowerCase() != oldExtension) {
      throw BusyMarkException(
        'writerside.topic-file.file-extension-mismatch',
        args: {'extension': oldExtension},
      );
    }
    final id = p.basenameWithoutExtension(fileName);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw const BusyMarkException('writerside.topic-file.file-name-invalid');
    }
    return fileName;
  }

  String _renamedTopicFileName(String oldFileName, String newFileName) {
    final directory = p.dirname(_normalizedReference(oldFileName));
    return directory == '.'
        ? newFileName
        : p.join(directory, newFileName).replaceAll(r'\', '/');
  }

  String _renamedReference(
    String reference, {
    required String oldTopicFileName,
    required String newTopicFileName,
    required String newFileName,
  }) {
    final normalized = _normalizedReference(reference);
    if (normalized == _normalizedReference(oldTopicFileName)) {
      return newTopicFileName;
    }
    return newFileName;
  }

  String _normalizedReference(String value) {
    return p.normalize(value.trim()).replaceAll(r'\', '/');
  }

  String _xmlSource(XmlDocument document) {
    return '${document.toXmlString(pretty: true, indent: '  ')}\n';
  }
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
    required this.path,
    required this.originalSource,
    required this.updatedSource,
  });

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
