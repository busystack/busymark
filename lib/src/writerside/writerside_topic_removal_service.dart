import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/linux_atomic_file_api.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../core/uri_utils.dart';
import 'writerside_model.dart';
import 'writerside_module_service.dart';
import 'writerside_project.dart';
import 'writerside_document.dart';
import 'writerside_document_resolver.dart';
import 'writerside_document_parser.dart';
import 'writerside_schema.dart';
import 'writerside_toc_presentation.dart';
import 'writerside_web_file_name.dart';

enum WritersideTopicRemovalMode { removeFromInstance, safeDeleteFile }

enum WritersideTopicUsageKind {
  tocElement,
  startPage,
  topicLink,
  include,
  otherTopicReference,
}

class WritersideTopicUsage {
  WritersideTopicUsage({
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    required this.reference,
    required this.relevant,
    required this.canUpdateAutomatically,
    this.span,
    this.moduleRoot,
    List<int>? nodePath,
  }) : nodePath = nodePath == null ? null : List.unmodifiable(nodePath);

  final WritersideTopicUsageKind kind;
  final String filePath;
  final int line;
  final int column;
  final String reference;
  final bool relevant;
  final bool canUpdateAutomatically;
  final SourceSpan? span;
  final String? moduleRoot;
  final List<int>? nodePath;
}

class WritersideTopicRedirectSource {
  WritersideTopicRedirectSource({
    required this.hostModuleRoot,
    required this.treePath,
    required this.instanceId,
    required Iterable<String> acceptedWebFileNames,
  }) : acceptedWebFileNames = List.unmodifiable(
         acceptedWebFileNames.toSet().toList()..sort(),
       );

  final String hostModuleRoot;
  final String treePath;
  final String? instanceId;
  final List<String> acceptedWebFileNames;
}

class WritersideTopicRedirectTarget {
  WritersideTopicRedirectTarget({
    required this.topicPath,
    required this.topicFileName,
    required this.label,
    required this.treePath,
    required List<int> nodePath,
  }) : nodePath = List.unmodifiable(nodePath);

  final String topicPath;
  final String topicFileName;
  final String label;
  final String treePath;
  final List<int> nodePath;
}

class WritersideTopicRemovalAnalysis {
  WritersideTopicRemovalAnalysis({
    required this.mode,
    String? projectRoot,
    String? targetModuleRoot,
    String? hostModuleRoot,
    String? moduleRoot,
    required this.topicPath,
    required this.topicFileName,
    required this.topicTitle,
    String? oldWebFileName,
    List<WritersideTopicRedirectSource> redirectSources = const [],
    required this.selectedTreePath,
    required List<int>? selectedNodePath,
    required this.childCount,
    required this.isStartPage,
    required List<WritersideTopicUsage> usages,
    required List<WritersideTopicRedirectTarget> redirectTargets,
    required this.fingerprint,
    List<String> projectModuleRoots = const [],
  }) : projectRoot =
           projectRoot ??
           moduleRoot ??
           targetModuleRoot ??
           (throw ArgumentError('A Writerside project root is required.')),
       targetModuleRoot =
           targetModuleRoot ??
           moduleRoot ??
           (throw ArgumentError('A Writerside topic owner is required.')),
       hostModuleRoot =
           hostModuleRoot ??
           targetModuleRoot ??
           moduleRoot ??
           (throw ArgumentError('A Writerside host module is required.')),
       oldWebFileName =
           oldWebFileName ??
           redirectSources.firstOrNull?.acceptedWebFileNames.firstOrNull ??
           '',
       redirectSources = List.unmodifiable(redirectSources),
       projectModuleRoots = List.unmodifiable(
         projectModuleRoots.map(normalizePath).toSet().toList()..sort(),
       ),
       selectedNodePath = selectedNodePath == null
           ? null
           : List.unmodifiable(selectedNodePath),
       usages = List.unmodifiable(usages),
       redirectTargets = List.unmodifiable(redirectTargets);

  final WritersideTopicRemovalMode mode;
  final String projectRoot;
  final String targetModuleRoot;
  final String hostModuleRoot;
  String get moduleRoot => targetModuleRoot;
  final String topicPath;
  final String topicFileName;
  final String? topicTitle;
  final String oldWebFileName;
  final List<WritersideTopicRedirectSource> redirectSources;
  final List<String> projectModuleRoots;
  final String? selectedTreePath;
  final List<int>? selectedNodePath;
  final int childCount;
  final bool isStartPage;
  final List<WritersideTopicUsage> usages;
  final List<WritersideTopicRedirectTarget> redirectTargets;
  final String fingerprint;

  List<WritersideTopicUsage> get relevantUsages =>
      usages.where((usage) => usage.relevant).toList(growable: false);

  List<WritersideTopicUsage> get blockingUsages => relevantUsages
      .where(
        (usage) => switch (mode) {
          WritersideTopicRemovalMode.removeFromInstance =>
            usage.kind == WritersideTopicUsageKind.startPage ||
                (usage.kind == WritersideTopicUsageKind.tocElement &&
                    !usage.canUpdateAutomatically) ||
                usage.kind == WritersideTopicUsageKind.topicLink ||
                usage.kind == WritersideTopicUsageKind.include ||
                usage.kind == WritersideTopicUsageKind.otherTopicReference,
          WritersideTopicRemovalMode.safeDeleteFile =>
            usage.kind == WritersideTopicUsageKind.startPage ||
                (usage.kind == WritersideTopicUsageKind.tocElement &&
                    !usage.canUpdateAutomatically) ||
                usage.kind == WritersideTopicUsageKind.topicLink ||
                usage.kind == WritersideTopicUsageKind.include ||
                usage.kind == WritersideTopicUsageKind.otherTopicReference,
        },
      )
      .toList(growable: false);

  bool get canUpdateUsagesAutomatically =>
      blockingUsages.every((usage) => usage.canUpdateAutomatically);
}

class WritersideTopicRemovalRequest {
  const WritersideTopicRemovalRequest({
    required this.analysis,
    this.updateUsagesAutomatically = false,
    this.redirectTarget,
  });

  final WritersideTopicRemovalAnalysis analysis;
  final bool updateUsagesAutomatically;
  final WritersideTopicRedirectTarget? redirectTarget;
}

class WritersideTopicRemovalResult {
  const WritersideTopicRemovalResult({
    required this.deletedFile,
    required this.orphaned,
    required this.promotedChildren,
    required this.redirectAdded,
    required this.updatedUsageFiles,
  });

  final bool deletedFile;
  final bool orphaned;
  final int promotedChildren;
  final bool redirectAdded;
  final List<String> updatedUsageFiles;
}

/// Implements Writerside's two-stage Remove from Instance / Safe Delete flow.
///
/// Analysis snapshots every semantic input and `.tree` file in the complete
/// Writerside project. Apply rebuilds that snapshot and refuses to mutate
/// anything if an input changed, so a reviewed dialog can never authorize a
/// stale refactoring.
class WritersideTopicRemovalService {
  const WritersideTopicRemovalService({
    this.moduleService = const WritersideModuleService(),
    this.projectService,
    this.treeDirectoryLister,
  });

  final WritersideModuleService moduleService;
  final WritersideProjectService? projectService;
  final WorkspaceDirectoryLister? treeDirectoryLister;

  Future<WritersideTopicRemovalAnalysis> analyze({
    WritersideProject? project,
    WritersideModule? module,
    String? projectRoot,
    required String topicPath,
    required WritersideTopicRemovalMode mode,
    String? selectedTreePath,
    List<int>? selectedNodePath,
  }) async {
    final root = project?.rootPath ?? projectRoot ?? module?.rootPath;
    if (root == null) {
      throw const BusyMarkException('writerside.topic.module-not-open');
    }
    final snapshot = await _snapshot(root, topicPath, loadedProject: project);
    final selectedTree = selectedTreePath == null
        ? null
        : _canonicalInputPath(snapshot.anchor, selectedTreePath);
    if (selectedTree != null && !snapshot.trees.containsKey(selectedTree)) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': selectedTree},
      );
    }
    if (mode == WritersideTopicRemovalMode.removeFromInstance &&
        selectedTree == null) {
      throw const BusyMarkException('writerside.toc.destination-required');
    }
    if (mode == WritersideTopicRemovalMode.removeFromInstance) {
      if (selectedNodePath == null) {
        throw const BusyMarkException('writerside.toc.destination-required');
      }
      final selectedElement = _elementAtPath(
        snapshot.trees[selectedTree]!.document.rootElement,
        selectedNodePath,
      );
      if (!_elementTargets(
        snapshot,
        selectedElement,
        snapshot.topic.filePath,
        tree: snapshot.trees[selectedTree]!,
      )) {
        throw BusyMarkException(
          'writerside.toc.path-invalid',
          args: {'path': selectedNodePath.join('/'), 'role': 'source'},
        );
      }
    }

    final selectedInstance = selectedTree == null
        ? null
        : snapshot.trees[selectedTree]!.owner.instances
              .where(
                (instance) => p.equals(instance.sourceTreePath, selectedTree),
              )
              .firstOrNull;
    if (mode == WritersideTopicRemovalMode.removeFromInstance &&
        selectedInstance == null) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': selectedTree},
      );
    }
    final activeTreeNodes = <String, TocNode>{};
    final participatingTopics = <String>{};
    final activeDocumentRanges = <String, List<SourceSpan>>{};
    if (selectedInstance != null) {
      final presenter = WritersideTocPresenter(
        module: snapshot.trees[selectedTree]!.owner,
        instance: selectedInstance,
        modulesByOrigin: snapshot.project.modulesByOrigin,
      );
      for (final node in selectedInstance.navigationTocRoots.expand(
        (root) => root.flatten(),
      )) {
        final presentation = presenter.present(node);
        final topic = presentation.topic;
        if (topic != null) {
          participatingTopics.add(normalizePath(topic.filePath));
          final owner = snapshot.project.topicOwnerForPath(topic.filePath);
          if (owner != null) {
            final resolved = const WritersideDocumentResolver().resolve(
              topic.document,
              WritersideResolveContext(
                module: owner,
                topic: topic,
                instance: selectedInstance,
                modulesByOrigin: snapshot.project.modulesByOrigin,
              ),
            );
            for (final documentNode in resolved.document.walk()) {
              final sourcePath = normalizePath(
                documentNode.provenance?.topicPath ??
                    documentNode.span.filePath,
              );
              // Authored references in this topic are checked against the
              // resolved node tree below. These ranges are only for content
              // pulled from another topic by an active include; retaining a
              // root span here would make every conditioned child look active.
              if (p.equals(sourcePath, normalizePath(topic.filePath))) {
                continue;
              }
              activeDocumentRanges
                  .putIfAbsent(sourcePath, () => <SourceSpan>[])
                  .add(documentNode.span);
            }
          }
        }
        if (topic != null &&
            p.equals(topic.filePath, snapshot.topic.filePath)) {
          activeTreeNodes[_treeNodeKey(
                node.span.filePath,
                node.span.startOffset,
              )] =
              node;
        }
      }
    }
    final usages = <WritersideTopicUsage>[];
    var childCount = 0;
    for (final tree in snapshot.trees.values) {
      final root = tree.document.rootElement;
      final startPage = root.getAttribute('start-page');
      if (startPage != null &&
          _couldTarget(snapshot, startPage, sourceModule: tree.owner)) {
        final span = _attributeSpan(tree, root, 'start-page');
        usages.add(
          _treeUsage(
            tree,
            element: root,
            attribute: 'start-page',
            kind: WritersideTopicUsageKind.startPage,
            reference: startPage,
            relevant:
                mode == WritersideTopicRemovalMode.safeDeleteFile ||
                (selectedTree != null &&
                    p.equals(tree.path, selectedTree) &&
                    selectedInstance?.startPage == startPage),
            canUpdateAutomatically: false,
            span: span,
          ),
        );
      }
      for (final entry in _tocEntries(root)) {
        final reference = _tocReference(entry.element);
        if (reference == null ||
            !_elementCouldTarget(snapshot, entry.element, tree: tree)) {
          continue;
        }
        final span = _attributeSpan(
          tree,
          entry.element,
          entry.element.getAttribute('topic') != null ? 'topic' : 'ref',
        );
        final activeNode =
            activeTreeNodes[_treeNodeKey(
              tree.path,
              _elementSpan(tree, entry.element).startOffset,
            )];
        final relevant =
            mode == WritersideTopicRemovalMode.safeDeleteFile ||
            activeNode != null;
        final automatic =
            _elementTargets(
              snapshot,
              entry.element,
              snapshot.topic.filePath,
              tree: tree,
            ) &&
            (mode == WritersideTopicRemovalMode.safeDeleteFile ||
                activeNode?.included != true);
        usages.add(
          _treeUsage(
            tree,
            element: entry.element,
            attribute: entry.element.getAttribute('topic') != null
                ? 'topic'
                : 'ref',
            kind: WritersideTopicUsageKind.tocElement,
            reference: reference,
            relevant: relevant,
            canUpdateAutomatically: automatic,
            span: span,
            nodePath: entry.path,
          ),
        );
        final directChildren = entry.element.childElements
            .where(_isTocElement)
            .length;
        if (relevant && automatic) {
          childCount += directChildren;
        }
      }
    }

    usages.addAll(
      _contentUsages(
        snapshot,
        mode: mode,
        selectedInstance: selectedInstance,
        participatingTopics: participatingTopics,
        activeDocumentRanges: activeDocumentRanges,
      ),
    );

    final preferredTree = selectedTree ?? _preferredTree(snapshot);
    final redirectSources = _redirectSources(snapshot, usages);
    return WritersideTopicRemovalAnalysis(
      mode: mode,
      projectRoot: snapshot.anchor.rootPath,
      targetModuleRoot: snapshot.module.rootPath,
      hostModuleRoot: selectedTree == null
          ? snapshot.module.rootPath
          : snapshot.trees[selectedTree]!.owner.rootPath,
      topicPath: snapshot.topic.filePath,
      topicFileName: snapshot.topic.fileName,
      topicTitle: snapshot.topic.title,
      oldWebFileName:
          redirectSources.firstOrNull?.acceptedWebFileNames.firstOrNull ??
          _effectiveWebFileName(snapshot, preferredTree),
      redirectSources: redirectSources,
      selectedTreePath: selectedTree,
      selectedNodePath: selectedNodePath,
      childCount: childCount,
      isStartPage: usages.any(
        (usage) =>
            usage.kind == WritersideTopicUsageKind.startPage && usage.relevant,
      ),
      usages: usages,
      redirectTargets: preferredTree == null
          ? const []
          : _redirectTargetsForAnalysis(
              snapshot,
              mode: mode,
              preferredTree: snapshot.trees[preferredTree]!,
            ),
      fingerprint: snapshot.fingerprint,
      projectModuleRoots: snapshot.moduleRoots,
    );
  }

  Future<WritersideTopicRemovalResult> apply(
    WritersideTopicRemovalRequest request, {
    void Function(Iterable<String>)? validateBeforeCommit,
  }) async {
    final analysis = request.analysis;
    final analyzedPaths = <String>{
      analysis.topicPath,
      if (analysis.selectedTreePath case final String treePath) treePath,
      for (final usage in analysis.usages) usage.filePath,
    };
    validateBeforeCommit?.call(analyzedPaths);
    final snapshot = await _snapshot(analysis.projectRoot, analysis.topicPath);
    if (!_sameStringList(snapshot.moduleRoots, analysis.projectModuleRoots) ||
        snapshot.fingerprint != analysis.fingerprint) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': analysis.topicPath},
      );
    }
    if (analysis.mode == WritersideTopicRemovalMode.safeDeleteFile &&
        analysis.isStartPage) {
      throw BusyMarkException(
        'writerside.topic-file.is-start-page',
        args: {'topic': analysis.topicFileName},
      );
    }
    final blocking = analysis.blockingUsages;
    if (blocking.isNotEmpty &&
        (!request.updateUsagesAutomatically ||
            !analysis.canUpdateUsagesAutomatically)) {
      throw BusyMarkException(
        'writerside.topic-removal.usages-remain',
        args: {'path': analysis.topicPath},
      );
    }

    final updatedSources = <String, String>{};
    final changedTreePaths = <String>{};
    var promotedChildren = 0;
    var redirectAdded = false;
    final treeDocuments = <String, XmlDocument>{
      for (final tree in snapshot.trees.values)
        tree.path: XmlDocument.parse(tree.source),
    };

    XmlElement? selectedRemovalElement;
    if (analysis.mode == WritersideTopicRemovalMode.removeFromInstance) {
      final treePath = analysis.selectedTreePath;
      final nodePath = analysis.selectedNodePath;
      if (treePath == null || nodePath == null) {
        throw const BusyMarkException('writerside.toc.destination-required');
      }
      final document = treeDocuments[normalizePath(treePath)];
      if (document == null) {
        throw BusyMarkException(
          'writerside.topic.tree-file-missing',
          args: {'path': treePath},
        );
      }
      selectedRemovalElement = _elementAtPath(document.rootElement, nodePath);
      if (!_elementTargets(
        snapshot,
        selectedRemovalElement,
        snapshot.topic.filePath,
        tree: snapshot.trees[normalizePath(treePath)]!,
      )) {
        throw BusyMarkException(
          'writerside.toc.path-invalid',
          args: {'path': nodePath.join('/'), 'role': 'source'},
        );
      }
    }
    final removedElements = Set<XmlElement>.identity();
    for (final usage in analysis.usages.where(
      (usage) =>
          usage.kind == WritersideTopicUsageKind.tocElement &&
          usage.relevant &&
          usage.canUpdateAutomatically,
    )) {
      final nodePath = usage.nodePath;
      final document = treeDocuments[normalizePath(usage.filePath)];
      if (nodePath != null && document != null) {
        removedElements.add(_elementAtPath(document.rootElement, nodePath));
      }
    }

    final redirectElements = <String, XmlElement>{};
    final redirect = request.redirectTarget;
    if (redirect != null) {
      if (!analysis.redirectTargets.any(
        (candidate) =>
            p.equals(candidate.treePath, redirect.treePath) &&
            _samePath(candidate.nodePath, redirect.nodePath) &&
            p.equals(candidate.topicPath, redirect.topicPath),
      )) {
        throw const BusyMarkException(
          'writerside.topic-removal.redirect-invalid',
        );
      }
      if (analysis.mode == WritersideTopicRemovalMode.removeFromInstance) {
        final redirectPath = normalizePath(redirect.treePath);
        final redirectDocument = treeDocuments[redirectPath];
        if (redirectDocument == null) {
          throw const BusyMarkException(
            'writerside.topic-removal.redirect-invalid',
          );
        }
        final element = _elementAtPath(
          redirectDocument.rootElement,
          redirect.nodePath,
        );
        if (!_elementTargets(
          snapshot,
          element,
          redirect.topicPath,
          tree: snapshot.trees[redirectPath]!,
        )) {
          throw const BusyMarkException(
            'writerside.topic-removal.redirect-invalid',
          );
        }
        redirectElements[redirectPath] = element;
      } else {
        final affectedTreePaths = <String>[
          for (final entry in treeDocuments.entries)
            if (_documentContainsTarget(
              snapshot,
              entry.value,
              snapshot.topic.filePath,
              tree: snapshot.trees[entry.key]!,
            ))
              entry.key,
        ];
        final targetTreePaths = affectedTreePaths.isEmpty
            ? <String>[normalizePath(redirect.treePath)]
            : affectedTreePaths;
        for (final treePath in targetTreePaths) {
          final document = treeDocuments[treePath];
          if (document == null) {
            throw const BusyMarkException(
              'writerside.topic-removal.redirect-invalid',
            );
          }
          final matches = _elementsTargetingPath(
            snapshot,
            document,
            redirect.topicPath,
            tree: snapshot.trees[treePath]!,
          );
          if (matches.length != 1) {
            throw const BusyMarkException(
              'writerside.topic-removal.redirect-invalid',
            );
          }
          redirectElements[treePath] = matches.single;
        }
      }

      for (final entry in redirectElements.entries) {
        final document = treeDocuments[entry.key]!;
        final transferredNames = _redirectNamesForTree(analysis, entry.key);
        final conflictingRedirect = transferredNames.any(
          (name) =>
              document
                  .findAllElements('toc-element')
                  .any(
                    (element) =>
                        !identical(element, entry.value) &&
                        !removedElements.contains(element) &&
                        (_acceptedWebFileNames(
                              snapshot,
                              element,
                              treePath: entry.key,
                            ).contains(name) ||
                            _elementPublishesWebFileName(
                              snapshot,
                              element,
                              name,
                              treePath: entry.key,
                            )),
                  ) ||
              _resolvedInstanceHasRedirectConflict(
                snapshot,
                treePath: entry.key,
                webFileName: name,
                redirectTopicPath: redirect.topicPath,
              ),
        );
        if (conflictingRedirect) {
          throw const BusyMarkException(
            'writerside.topic-removal.redirect-invalid',
          );
        }
      }
      for (final entry in redirectElements.entries) {
        final existingNames = _acceptedWebFileNames(
          snapshot,
          entry.value,
          treePath: entry.key,
        );
        final oldNames =
            (entry.value.getAttribute('accepts-web-file-names') ?? '')
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList();
        var changed = false;
        for (final name in _redirectNamesForTree(analysis, entry.key)) {
          if (existingNames.contains(name) ||
              _elementPublishesWebFileName(
                snapshot,
                entry.value,
                name,
                treePath: entry.key,
              )) {
            continue;
          }
          if (!oldNames.contains(name)) {
            oldNames.add(name);
            changed = true;
          }
        }
        if (changed) {
          entry.value.setAttribute(
            'accepts-web-file-names',
            oldNames.join(','),
          );
          changedTreePaths.add(entry.key);
          redirectAdded = true;
        }
      }
    }

    final removalsByTree = <String, List<List<int>>>{};
    for (final usage in analysis.usages.where(
      (usage) =>
          usage.kind == WritersideTopicUsageKind.tocElement &&
          usage.relevant &&
          usage.canUpdateAutomatically &&
          usage.nodePath != null,
    )) {
      removalsByTree
          .putIfAbsent(normalizePath(usage.filePath), () => [])
          .add(usage.nodePath!);
    }
    for (final entry in removalsByTree.entries) {
      final document = treeDocuments[entry.key]!;
      final paths = entry.value..sort((a, b) => _comparePathsForRemoval(b, a));
      for (final nodePath in paths) {
        promotedChildren += _removeAndPromote(
          _elementAtPath(document.rootElement, nodePath),
        );
      }
      changedTreePaths.add(entry.key);
    }

    for (final path in changedTreePaths) {
      updatedSources[path] = _xmlSource(treeDocuments[path]!);
    }

    final updatedUsageFiles = <String>[];
    if (request.updateUsagesAutomatically) {
      final sourcePaths = analysis.blockingUsages
          .where(
            (usage) =>
                usage.kind == WritersideTopicUsageKind.topicLink ||
                usage.kind == WritersideTopicUsageKind.include,
          )
          .map((usage) => normalizePath(usage.filePath))
          .toSet();
      for (final path in sourcePaths) {
        final sourceTopic = snapshot.project.modules
            .expand((module) => module.topics)
            .firstWhere((topic) => p.equals(topic.filePath, path));
        final original = snapshot.sources[path]!;
        final updated = _rewriteReviewedTopicUsages(
          snapshot,
          sourceTopic,
          original,
          analysis.usages.where(
            (usage) =>
                usage.relevant &&
                usage.canUpdateAutomatically &&
                p.equals(usage.filePath, path),
          ),
        );
        if (updated == original) {
          throw BusyMarkException(
            'writerside.topic-removal.usages-remain',
            args: {'path': path},
          );
        }
        updatedSources[path] = updated;
        updatedUsageFiles.add(path);
      }
    }

    final sourceUsageRemains = _plannedUsageRemains(
      analysis,
      updateUsagesAutomatically: request.updateUsagesAutomatically,
    );
    if (analysis.mode == WritersideTopicRemovalMode.safeDeleteFile &&
        sourceUsageRemains) {
      throw BusyMarkException(
        'writerside.topic-removal.usages-remain',
        args: {'path': analysis.topicPath},
      );
    }

    final edits = <_SourceEdit>[
      for (final entry in updatedSources.entries)
        if (entry.value != snapshot.sources[entry.key])
          _SourceEdit(
            path: entry.key,
            original: snapshot.sources[entry.key]!,
            updated: entry.value,
          ),
    ];
    final applied = <_SourceEdit>[];
    final affected = <String>{
      ...edits.map((edit) => edit.path),
      analysis.topicPath,
    };
    void validate() => validateBeforeCommit?.call(affected);
    try {
      for (final edit in edits) {
        await _replaceAtomically(
          snapshot.anchor,
          edit.path,
          edit.updated,
          expected: edit.original,
          validateBeforeCommit: validate,
        );
        applied.add(edit);
      }
      await _ensureExpectedState(snapshot, edits);
      validate();
      if (analysis.mode == WritersideTopicRemovalMode.safeDeleteFile) {
        await _deleteExpectedFile(
          snapshot.anchor,
          snapshot.topic.filePath,
          expected: snapshot.sources[snapshot.topic.filePath]!,
          validateBeforeCommit: validate,
        );
      }
    } on Object catch (error, stackTrace) {
      final rollbackFailures = <String>[
        if (error is BusyMarkException &&
            error.code == 'writerside.topic-removal.rollback-failed')
          '${error.args['paths'] ?? ''}',
      ]..removeWhere((path) => path.isEmpty);
      for (final edit in applied.reversed) {
        try {
          await _replaceAtomically(
            snapshot.anchor,
            edit.path,
            edit.original,
            expected: edit.updated,
          );
        } on Object {
          // Never overwrite a file changed by another process during rollback.
          rollbackFailures.add(edit.path);
        }
      }
      if (rollbackFailures.isNotEmpty) {
        throw BusyMarkException(
          'writerside.topic-removal.rollback-failed',
          args: {'paths': rollbackFailures.join(', ')},
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    final orphaned = analysis.mode == WritersideTopicRemovalMode.safeDeleteFile
        ? true
        : !sourceUsageRemains;
    return WritersideTopicRemovalResult(
      deletedFile: analysis.mode == WritersideTopicRemovalMode.safeDeleteFile,
      orphaned: orphaned,
      promotedChildren: promotedChildren,
      redirectAdded: redirectAdded,
      updatedUsageFiles: List.unmodifiable(updatedUsageFiles),
    );
  }

  Future<_RemovalSnapshot> _snapshot(
    String projectRoot,
    String requestedTopicPath, {
    WritersideProject? loadedProject,
  }) async {
    final anchor = await captureCanonicalDirectoryAnchor(projectRoot);
    final loader =
        projectService ??
        WritersideProjectService(
          moduleService: moduleService,
          scanOptions: moduleService.scanOptions,
        );
    final project = loadedProject ?? await loader.load(anchor.rootPath);
    if (!project.moduleDiscoveryComplete) {
      throw BusyMarkException(
        'writerside.topic-file.project-discovery-incomplete',
        args: {'path': anchor.rootPath},
      );
    }
    for (final candidate in project.modules) {
      if (!candidate.topicDiscoveryComplete ||
          candidate.unparsedTopicReferences.isNotEmpty ||
          !candidate.variablesAvailable ||
          candidate.topics.any((topic) => !topic.document.isWellFormed)) {
        throw BusyMarkException(
          'writerside.topic-removal.scan-failed',
          args: {
            'path': candidate.rootPath,
            'error': 'writerside.topic-file.incomplete-project-index',
          },
        );
      }
    }
    final safeTopicPath = _canonicalInputPath(anchor, requestedTopicPath);
    final module = project.topicOwnerForPath(safeTopicPath);
    final topic = module?.topics
        .where(
          (candidate) =>
              p.equals(normalizePath(candidate.filePath), safeTopicPath),
        )
        .firstOrNull;
    if (module == null || topic == null) {
      throw BusyMarkException(
        'writerside.topic-file.not-found',
        args: {'path': safeTopicPath},
      );
    }

    final sources = <String, String>{};
    final redirectRules = <String, Map<String, Set<String>>>{};
    for (final candidate in project.modules) {
      final inputPaths = <String>{
        candidate.config.filePath,
        for (final sourceTopic in candidate.topics) sourceTopic.filePath,
        if (candidate.config.varsFile case final path?)
          p.join(candidate.rootPath, path),
        if (candidate.config.instanceGroupsFile case final path?)
          p.join(candidate.rootPath, path),
      };
      for (final input in inputPaths) {
        final path = _canonicalInputPath(anchor, input);
        sources[path] = await _readRegularFile(anchor, path);
      }
      final redirectRulesPath = _canonicalInputPath(
        anchor,
        p.join(candidate.rootPath, 'redirection-rules.xml'),
      );
      if (await FileSystemEntity.type(redirectRulesPath, followLinks: false) ==
          FileSystemEntityType.notFound) {
        continue;
      }
      try {
        final source = await _readRegularFile(anchor, redirectRulesPath);
        final document = XmlDocument.parse(source);
        sources[redirectRulesPath] = source;
        final moduleRules = redirectRules.putIfAbsent(
          candidate.rootPath,
          () => <String, Set<String>>{},
        );
        for (final rule in document.findAllElements('rule')) {
          final id = rule.getAttribute('id')?.trim();
          if (id == null || id.isEmpty) continue;
          final accepted = moduleRules.putIfAbsent(id, () => <String>{});
          for (final element in rule.findElements('accepts')) {
            accepted.addAll(
              element.innerText
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty),
            );
          }
        }
      } on BusyMarkException {
        rethrow;
      } on Object catch (error) {
        throw BusyMarkException(
          'writerside.topic-removal.scan-failed',
          args: {'path': redirectRulesPath, 'error': '$error'},
        );
      }
    }

    final trees = <String, _TreeSnapshot>{};
    try {
      final scan = await scanWorkspaceEntities(
        anchor.rootPath,
        options: WorkspaceScanOptions(
          maxParsedFileBytes: moduleService.scanOptions.maxParsedFileBytes,
          maxParsedDocuments: moduleService.scanOptions.maxParsedDocuments,
          maxTreeEntries: moduleService.scanOptions.maxTreeEntries,
          followLinks: false,
          includeUnsupportedFiles: true,
          includeDirectories: false,
          includeHiddenDirectories: true,
          includeExcludedDirectories: true,
        ),
        directoryLister: treeDirectoryLister,
      );
      if (!scan.traversalComplete || scan.diagnostics.isNotEmpty) {
        final diagnostic = scan.diagnostics.first;
        throw BusyMarkException(
          'writerside.topic-removal.scan-failed',
          args: {'path': diagnostic.filePath, 'error': diagnostic.code},
        );
      }
      var parsedTrees = 0;
      for (final entity in scan.entities) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.tree') {
          continue;
        }
        if (parsedTrees >= moduleService.scanOptions.maxParsedDocuments) {
          throw BusyMarkException(
            'writerside.topic-removal.scan-failed',
            args: {
              'path': entity.path,
              'error': 'workspace.scan.document-limit',
            },
          );
        }
        parsedTrees++;
        final path = _canonicalInputPath(anchor, entity.path);
        final source = await _readRegularFile(
          anchor,
          path,
          maxBytes: moduleService.scanOptions.maxParsedFileBytes,
        );
        final document = XmlDocument.parse(source);
        if (document.rootElement.name.local != 'instance-profile') {
          throw FormatException('.tree root must be <instance-profile>.', path);
        }
        sources[path] = source;
        final owner = _mostSpecificModuleForPath(project.modules, path);
        if (owner == null) {
          throw BusyMarkException(
            'writerside.topic-removal.scan-failed',
            args: {'path': path, 'error': 'writerside.topic.module-not-open'},
          );
        }
        trees[path] = _TreeSnapshot(
          path: path,
          source: source,
          document: document,
          owner: owner,
        );
      }
    } on BusyMarkException {
      rethrow;
    } on Object catch (error) {
      throw BusyMarkException(
        'writerside.topic-removal.scan-failed',
        args: {'path': anchor.rootPath, 'error': '$error'},
      );
    }
    for (final candidate in project.modules) {
      for (final configured in candidate.config.instanceSources) {
        final configuredPath = _canonicalInputPath(
          anchor,
          p.join(candidate.rootPath, configured),
        );
        if (!trees.containsKey(configuredPath)) {
          throw BusyMarkException(
            'writerside.topic-file.tree-missing',
            args: {'path': configuredPath},
          );
        }
      }
    }
    return _RemovalSnapshot(
      anchor: anchor,
      project: project,
      module: module,
      topic: topic,
      sources: Map.unmodifiable(sources),
      trees: Map.unmodifiable(trees),
      redirectRules: Map.unmodifiable(redirectRules),
      moduleRoots: project.modules.map((module) => module.rootPath).toList()
        ..sort(),
      fingerprint: _fingerprint(sources),
    );
  }

  String _canonicalInputPath(CanonicalPathAnchor anchor, String path) {
    final absolute = normalizePath(
      p.isAbsolute(path) ? path : p.join(anchor.rootPath, path),
    );
    if (!p.equals(absolute, anchor.rootPath) &&
        !p.isWithin(anchor.rootPath, absolute) &&
        !p.isWithin(anchor.requestedRootPath, absolute)) {
      throw BusyMarkException(
        'writerside.topic.module-root-missing',
        args: {'path': path},
      );
    }
    if (p.isWithin(anchor.requestedRootPath, absolute) &&
        !p.equals(anchor.requestedRootPath, anchor.rootPath)) {
      return p.normalize(
        p.join(
          anchor.rootPath,
          p.relative(absolute, from: anchor.requestedRootPath),
        ),
      );
    }
    return absolute;
  }

  Future<String> _readRegularFile(
    CanonicalPathAnchor anchor,
    String path, {
    int? maxBytes,
  }) async {
    try {
      final resolution = await resolveAnchoredPath(
        anchor,
        path,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.file) {
        throw const FileSystemException('Not a regular file');
      }
      if (maxBytes != null && await File(resolution.path).length() > maxBytes) {
        throw const FileSystemException('File exceeds semantic parse limit');
      }
      return await File(resolution.path).readAsString();
    } on BusyMarkException {
      rethrow;
    } on Object catch (error) {
      throw BusyMarkException(
        'writerside.topic-removal.scan-failed',
        args: {'path': path, 'error': '$error'},
      );
    }
  }

  bool _targets(
    _RemovalSnapshot snapshot,
    String reference, {
    WritersideTopic? fromTopic,
    WritersideModule? sourceModule,
    String? origin,
  }) {
    final source =
        sourceModule ??
        (fromTopic == null
            ? snapshot.module
            : snapshot.project.topicOwnerForPath(fromTopic.filePath)) ??
        snapshot.module;
    final targetModule = origin == null
        ? source
        : snapshot.project.modulesByOrigin[origin];
    if (targetModule == null) return false;
    final expansion = _expandReference(
      snapshot,
      reference,
      fromTopic,
      sourceModule: source,
    );
    if (expansion.unresolved || expansion.values.isEmpty) {
      return false;
    }
    for (final value in expansion.values) {
      final matches = targetModule.topicsMatchingReference(
        value,
        fromTopic: p.equals(targetModule.rootPath, source.rootPath)
            ? fromTopic
            : null,
      );
      if (matches.length != 1 ||
          !p.equals(matches.single.filePath, snapshot.topic.filePath)) {
        return false;
      }
    }
    return true;
  }

  bool _couldTarget(
    _RemovalSnapshot snapshot,
    String reference, {
    WritersideTopic? fromTopic,
    WritersideModule? sourceModule,
    String? origin,
  }) {
    final source =
        sourceModule ??
        (fromTopic == null
            ? snapshot.module
            : snapshot.project.topicOwnerForPath(fromTopic.filePath)) ??
        snapshot.module;
    final targetModule = origin == null
        ? source
        : snapshot.project.modulesByOrigin[origin];
    if (targetModule == null) {
      return _referencePatternCouldMatchTopic(
        reference,
        snapshot.topic,
        fromTopic: fromTopic,
      );
    }
    final expansion = _expandReference(
      snapshot,
      reference,
      fromTopic,
      sourceModule: source,
    );
    for (final value in expansion.values) {
      if (targetModule
          .topicsMatchingReference(value, fromTopic: fromTopic)
          .any(
            (candidate) =>
                p.equals(candidate.filePath, snapshot.topic.filePath),
          )) {
        return true;
      }
    }
    return expansion.unresolved &&
        expansion.patterns.any(
          (pattern) => _referencePatternCouldMatchTopic(
            pattern,
            snapshot.topic,
            fromTopic: fromTopic,
          ),
        );
  }

  _ReferenceExpansion _expandReference(
    _RemovalSnapshot snapshot,
    String reference,
    WritersideTopic? fromTopic, {
    WritersideModule? sourceModule,
  }) {
    final normalizedReference = _decodeWritersideVariableEscapes(reference);
    final pending = <String>[normalizedReference];
    final seen = <String>{normalizedReference};
    final resolved = <String>{};
    final unresolved = <String>{};
    var index = 0;
    while (index < pending.length && seen.length <= 256) {
      final candidate = pending[index++];
      final match = _writersideVariableReference.firstMatch(candidate);
      if (match == null) {
        resolved.add(candidate);
        continue;
      }
      final token = match.group(0)!;
      final values = _variableValues(
        snapshot,
        match.group(1)!,
        fromTopic,
        sourceModule: sourceModule,
      );
      if (values.isEmpty) {
        unresolved.add(candidate);
        continue;
      }
      var expandedAny = false;
      for (final value in values) {
        final expanded = candidate.replaceAll(token, value);
        if (expanded == candidate) {
          continue;
        }
        expandedAny = true;
        if (seen.add(expanded)) {
          pending.add(expanded);
        }
      }
      if (!expandedAny) {
        unresolved.add(candidate);
      }
    }
    if (index < pending.length || seen.length > 256) {
      unresolved.addAll(pending.skip(index));
    }
    return _ReferenceExpansion(
      values: resolved,
      patterns: unresolved,
      unresolved: unresolved.isNotEmpty,
    );
  }

  Set<String> _variableValues(
    _RemovalSnapshot snapshot,
    String name,
    WritersideTopic? fromTopic, {
    WritersideModule? sourceModule,
  }) {
    final module = sourceModule ?? snapshot.module;
    final configured = module.variables
        .where((variable) => variable.name == name)
        .map((variable) => variable.value)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (configured.isNotEmpty) {
      return configured;
    }
    return switch (name) {
      'thisTopic' when fromTopic != null => {fromTopic.id},
      'currentId' => {for (final instance in module.instances) instance.id},
      'instance' => {for (final instance in module.instances) instance.name},
      'instance-lowercase' => {
        for (final instance in module.instances) instance.name.toLowerCase(),
      },
      _ => const <String>{},
    };
  }

  bool _referencePatternCouldMatchTopic(
    String reference,
    WritersideTopic target, {
    WritersideTopic? fromTopic,
  }) {
    final expression = StringBuffer('^');
    var offset = 0;
    for (final match in _writersideVariableReference.allMatches(reference)) {
      expression.write(RegExp.escape(reference.substring(offset, match.start)));
      expression.write('.*');
      offset = match.end;
    }
    expression
      ..write(RegExp.escape(reference.substring(offset)))
      ..write(r'$');
    final pattern = RegExp(expression.toString());
    final candidates = <String>{
      target.fileName,
      target.baseName,
      if (fromTopic != null)
        p.posix.relative(
          target.fileName,
          from: p.posix.dirname(fromTopic.fileName),
        ),
    };
    return candidates.any(
      (candidate) => pattern.hasMatch(candidate.replaceAll(r'\', '/')),
    );
  }

  bool _elementTargets(
    _RemovalSnapshot snapshot,
    XmlElement element,
    String topicPath, {
    required _TreeSnapshot tree,
  }) {
    final reference = _tocReference(element);
    if (reference == null) {
      return false;
    }
    final targetModule = element.getAttribute('origin') == null
        ? tree.owner
        : snapshot.project.modulesByOrigin[element.getAttribute('origin')];
    if (targetModule == null) return false;
    final expansion = _expandReference(
      snapshot,
      reference,
      null,
      sourceModule: tree.owner,
    );
    if (expansion.unresolved || expansion.values.isEmpty) return false;
    for (final value in expansion.values) {
      final matches = targetModule.topicsMatchingReference(value);
      if (matches.length != 1 ||
          !p.equals(matches.single.filePath, topicPath)) {
        return false;
      }
    }
    return true;
  }

  bool _elementCouldTarget(
    _RemovalSnapshot snapshot,
    XmlElement element, {
    required _TreeSnapshot tree,
  }) {
    final reference = _tocReference(element);
    return reference != null &&
        _couldTarget(
          snapshot,
          reference,
          sourceModule: tree.owner,
          origin: element.getAttribute('origin'),
        );
  }

  WritersideTopicUsage _treeUsage(
    _TreeSnapshot tree, {
    required XmlElement element,
    required String attribute,
    required WritersideTopicUsageKind kind,
    required String reference,
    required bool relevant,
    required bool canUpdateAutomatically,
    required SourceSpan span,
    List<int>? nodePath,
  }) {
    return WritersideTopicUsage(
      kind: kind,
      filePath: tree.path,
      line: span.startLine,
      column: span.startColumn,
      reference: reference,
      relevant: relevant,
      canUpdateAutomatically: canUpdateAutomatically,
      span: span,
      moduleRoot: tree.owner.rootPath,
      nodePath: nodePath,
    );
  }

  SourceSpan _elementSpan(_TreeSnapshot tree, XmlElement element) {
    final authored = <XmlElement>[
      tree.document.rootElement,
      ...tree.document.rootElement.descendants.whereType<XmlElement>(),
    ];
    final index = authored.indexWhere(
      (candidate) => identical(candidate, element),
    );
    final semantic = const WritersideDocumentParser()
        .parseXml(filePath: tree.path, source: tree.source)
        .elements
        .toList();
    if (index >= 0 && index < semantic.length) return semantic[index].span;
    return SourceSpan.fromOffsets(
      filePath: tree.path,
      source: tree.source,
      startOffset: 0,
      endOffset: 0,
    );
  }

  SourceSpan _attributeSpan(
    _TreeSnapshot tree,
    XmlElement element,
    String attribute,
  ) {
    final authored = <XmlElement>[
      tree.document.rootElement,
      ...tree.document.rootElement.descendants.whereType<XmlElement>(),
    ];
    final index = authored.indexWhere(
      (candidate) => identical(candidate, element),
    );
    final semantic = const WritersideDocumentParser()
        .parseXml(filePath: tree.path, source: tree.source)
        .elements
        .toList();
    if (index >= 0 && index < semantic.length) {
      return semantic[index].attributeSpans[attribute] ?? semantic[index].span;
    }
    return _elementSpan(tree, element);
  }

  List<WritersideTopicUsage> _contentUsages(
    _RemovalSnapshot snapshot, {
    required WritersideTopicRemovalMode mode,
    required WritersideInstance? selectedInstance,
    required Set<String> participatingTopics,
    required Map<String, List<SourceSpan>> activeDocumentRanges,
  }) {
    final targetSymbol = snapshot.project.index.symbols
        .where(
          (symbol) =>
              symbol.kind == WritersideSymbolKind.topic &&
              p.equals(symbol.filePath, snapshot.topic.filePath) &&
              symbol.name == snapshot.topic.id,
        )
        .firstOrNull;
    final definitelyIndexed = targetSymbol == null
        ? const <WritersideReference>{}
        : snapshot.project.index.findUsages(targetSymbol).toSet();
    final result = <WritersideTopicUsage>[];
    final seen = <String>{};
    for (final reference in snapshot.project.index.references.where(
      (reference) => reference.kind == WritersideSymbolKind.topic,
    )) {
      if (p.extension(reference.filePath).toLowerCase() == '.tree' ||
          p.equals(reference.filePath, snapshot.topic.filePath) ||
          hasUriScheme(reference.value)) {
        continue;
      }
      final sourceModule =
          snapshot.project.index.modulesById[reference.moduleId];
      if (sourceModule == null) continue;
      final sourceTopic = sourceModule.topics
          .where((topic) => p.equals(topic.filePath, reference.filePath))
          .firstOrNull;
      if (sourceTopic == null) continue;
      final semanticTargets = snapshot.project.index
          .definitions(
            reference.value.split('#').first,
            moduleId: reference.moduleId,
            origin: reference.origin,
            kind: WritersideSymbolKind.topic,
            filePath: reference.filePath,
            referenceOffset: reference.span.startOffset,
          )
          .where((symbol) => symbol.kind == WritersideSymbolKind.topic)
          .toList();
      final exactTarget = semanticTargets.any(
        (symbol) => p.equals(symbol.filePath, snapshot.topic.filePath),
      );
      final couldTarget =
          exactTarget ||
          _couldTarget(
            snapshot,
            _referenceWithoutAnchor(reference.value),
            fromTopic: sourceTopic,
            sourceModule: sourceModule,
            origin: reference.origin,
          );
      if (!couldTarget) continue;
      final key =
          '${reference.filePath}:${reference.span.startOffset}:'
          '${reference.span.endOffset}';
      if (!seen.add(key)) continue;
      final element = _elementContainingReference(sourceTopic, reference.span);
      final kind = switch (element?.semanticKind) {
        WritersideSemanticKind.include => WritersideTopicUsageKind.include,
        WritersideSemanticKind.card =>
          WritersideTopicUsageKind.otherTopicReference,
        _ => WritersideTopicUsageKind.topicLink,
      };
      final source = snapshot.sources[normalizePath(sourceTopic.filePath)]!;
      final expandedExact = _targets(
        snapshot,
        _referenceWithoutAnchor(reference.value),
        fromTopic: sourceTopic,
        sourceModule: sourceModule,
        origin: reference.origin,
      );
      final uniqueTarget =
          expandedExact ||
          (exactTarget &&
              semanticTargets
                      .map((symbol) => normalizePath(symbol.filePath))
                      .toSet()
                      .length ==
                  1 &&
              (definitelyIndexed.contains(reference) ||
                  semanticTargets.isNotEmpty));
      final automatic =
          uniqueTarget &&
          kind != WritersideTopicUsageKind.otherTopicReference &&
          _sourceReplacementForUsage(
                sourceTopic,
                source,
                kind,
                reference.span,
              ) !=
              null;
      final relevant =
          mode == WritersideTopicRemovalMode.safeDeleteFile ||
          (selectedInstance != null &&
              ((participatingTopics.contains(
                        normalizePath(sourceTopic.filePath),
                      ) &&
                      _referenceActiveInInstance(
                        snapshot,
                        sourceModule,
                        sourceTopic,
                        selectedInstance,
                        reference.span,
                      )) ||
                  (activeDocumentRanges[normalizePath(sourceTopic.filePath)] ??
                          const <SourceSpan>[])
                      .any(
                        (span) =>
                            span.startOffset <= reference.span.startOffset &&
                            span.endOffset >= reference.span.endOffset,
                      )));
      result.add(
        WritersideTopicUsage(
          kind: kind,
          filePath: reference.filePath,
          line: reference.span.startLine,
          column: reference.span.startColumn,
          reference: reference.sourceValue ?? reference.value,
          relevant: relevant,
          canUpdateAutomatically: automatic,
          span: reference.span,
          moduleRoot: sourceModule.rootPath,
        ),
      );
    }
    return result;
  }

  WritersideElementNode? _elementContainingReference(
    WritersideTopic topic,
    SourceSpan span,
  ) {
    final matches =
        topic.document.elements
            .where(
              (element) =>
                  element.span.startOffset <= span.startOffset &&
                  element.span.endOffset >= span.endOffset,
            )
            .toList()
          ..sort(
            (a, b) => (a.span.endOffset - a.span.startOffset).compareTo(
              b.span.endOffset - b.span.startOffset,
            ),
          );
    return matches.firstOrNull;
  }

  bool _referenceActiveInInstance(
    _RemovalSnapshot snapshot,
    WritersideModule sourceModule,
    WritersideTopic sourceTopic,
    WritersideInstance selectedInstance,
    SourceSpan span,
  ) {
    final sourceElement = _elementContainingReference(sourceTopic, span);
    if (sourceElement?.semanticKind == WritersideSemanticKind.include) {
      return sourceTopic.document
          .walk()
          .whereType<WritersideElementNode>()
          .where(
            (element) =>
                p.equals(element.span.filePath, span.filePath) &&
                element.span.startOffset <= span.startOffset &&
                element.span.endOffset >= span.endOffset,
          )
          .every(
            (element) => _matchesInstanceCondition(
              element.attributes['instance'],
              sourceModule,
              selectedInstance.id,
            ),
          );
    }
    final authoredContainer =
        sourceTopic.document
            .walk()
            .where(
              (node) =>
                  p.equals(node.span.filePath, span.filePath) &&
                  node.span.startOffset <= span.startOffset &&
                  node.span.endOffset >= span.endOffset,
            )
            .toList()
          ..sort(
            (a, b) => (a.span.endOffset - a.span.startOffset).compareTo(
              b.span.endOffset - b.span.startOffset,
            ),
          );
    final authoredSpan = sourceElement?.span ?? authoredContainer.first.span;
    final resolved = const WritersideDocumentResolver().resolve(
      sourceTopic.document,
      WritersideResolveContext(
        module: sourceModule,
        topic: sourceTopic,
        instance: selectedInstance,
        modulesByOrigin: snapshot.project.modulesByOrigin,
      ),
    );
    return resolved.document.walk().any(
      (node) =>
          p.equals(node.span.filePath, authoredSpan.filePath) &&
          node.span.startOffset == authoredSpan.startOffset &&
          node.span.endOffset == authoredSpan.endOffset,
    );
  }

  bool _matchesInstanceCondition(
    String? condition,
    WritersideModule module,
    String instanceId,
  ) {
    if (condition == null || condition.trim().isEmpty) return true;
    final trimmed = condition.trim();
    final negated = trimmed.startsWith('!');
    final body = negated ? trimmed.substring(1) : trimmed;
    final matches = body
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .any(
          (token) => token.startsWith('@')
              ? module.instanceGroups?.groups[token.substring(1)]?.instanceIds
                        .contains(instanceId) ==
                    true
              : token == instanceId,
        );
    return negated ? !matches : matches;
  }

  _TextReplacement? _sourceReplacementForUsage(
    WritersideTopic topic,
    String source,
    WritersideTopicUsageKind kind,
    SourceSpan span,
  ) {
    if (kind == WritersideTopicUsageKind.include) {
      final element = _elementContainingReference(topic, span);
      if (element?.semanticKind != WritersideSemanticKind.include) return null;
      return _TextReplacement(
        element!.span.startOffset,
        element.span.endOffset,
        '',
      );
    }
    if (kind != WritersideTopicUsageKind.topicLink) return null;
    for (final match in _markdownLinkPattern.allMatches(source)) {
      if (match.start <= span.startOffset && match.end >= span.endOffset) {
        return _TextReplacement(match.start, match.end, match.group(1)!);
      }
    }
    for (final match in _xmlAnchorPattern.allMatches(source)) {
      if (match.start <= span.startOffset && match.end >= span.endOffset) {
        return _TextReplacement(match.start, match.end, match.group(2)!);
      }
    }
    return null;
  }

  String _rewriteReviewedTopicUsages(
    _RemovalSnapshot snapshot,
    WritersideTopic topic,
    String source,
    Iterable<WritersideTopicUsage> usages,
  ) {
    final replacements = <_TextReplacement>[];
    for (final usage in usages) {
      final span = usage.span;
      if (span == null) continue;
      final replacement = _sourceReplacementForUsage(
        topic,
        source,
        usage.kind,
        span,
      );
      if (replacement != null) replacements.add(replacement);
    }
    replacements.sort((a, b) => b.start.compareTo(a.start));
    var updated = source;
    var previousStart = source.length + 1;
    for (final replacement in replacements) {
      if (replacement.end > previousStart) continue;
      updated = updated.replaceRange(
        replacement.start,
        replacement.end,
        replacement.text,
      );
      previousStart = replacement.start;
    }
    return updated;
  }

  bool _plannedUsageRemains(
    WritersideTopicRemovalAnalysis analysis, {
    required bool updateUsagesAutomatically,
  }) {
    for (final usage in analysis.usages) {
      if (!usage.relevant) return true;
      if (usage.kind == WritersideTopicUsageKind.tocElement &&
          usage.canUpdateAutomatically) {
        continue;
      }
      if (updateUsagesAutomatically &&
          usage.canUpdateAutomatically &&
          (usage.kind == WritersideTopicUsageKind.topicLink ||
              usage.kind == WritersideTopicUsageKind.include)) {
        continue;
      }
      return true;
    }
    return false;
  }

  List<WritersideTopicRedirectSource> _redirectSources(
    _RemovalSnapshot snapshot,
    List<WritersideTopicUsage> usages,
  ) {
    final result = <WritersideTopicRedirectSource>[];
    for (final usage in usages.where(
      (usage) =>
          usage.kind == WritersideTopicUsageKind.tocElement && usage.relevant,
    )) {
      final tree = snapshot.trees[normalizePath(usage.filePath)];
      final nodePath = usage.nodePath;
      if (tree == null || nodePath == null) continue;
      final element = _elementAtPath(tree.document.rootElement, nodePath);
      final instance = tree.owner.instances
          .where((candidate) => p.equals(candidate.sourceTreePath, tree.path))
          .firstOrNull;
      final names = <String>{
        _effectiveWebFileName(snapshot, tree.path),
        ..._acceptedWebFileNames(snapshot, element, treePath: tree.path),
      };
      result.add(
        WritersideTopicRedirectSource(
          hostModuleRoot: tree.owner.rootPath,
          treePath: tree.path,
          instanceId: instance?.id,
          acceptedWebFileNames: names,
        ),
      );
    }
    return result;
  }

  Set<String> _redirectNamesForTree(
    WritersideTopicRemovalAnalysis analysis,
    String treePath,
  ) {
    final exact = <String>{
      for (final source in analysis.redirectSources)
        if (p.equals(source.treePath, treePath)) ...source.acceptedWebFileNames,
    };
    if (exact.isNotEmpty) return exact;
    return analysis.oldWebFileName.isEmpty
        ? const <String>{}
        : {analysis.oldWebFileName};
  }

  String? _preferredTree(_RemovalSnapshot snapshot) {
    for (final configured in snapshot.module.config.instanceSources) {
      final candidate = normalizePath(
        p.join(snapshot.module.rootPath, configured),
      );
      if (snapshot.trees.containsKey(candidate)) {
        return candidate;
      }
    }
    return snapshot.trees.keys.firstOrNull;
  }

  List<WritersideTopicRedirectTarget> _redirectTargetsForAnalysis(
    _RemovalSnapshot snapshot, {
    required WritersideTopicRemovalMode mode,
    required _TreeSnapshot preferredTree,
  }) {
    if (mode == WritersideTopicRemovalMode.removeFromInstance) {
      return _resolvedRedirectTargets(snapshot, preferredTree);
    }
    final affectedTrees = snapshot.trees.values
        .where(
          (tree) => _documentContainsTarget(
            snapshot,
            tree.document,
            snapshot.topic.filePath,
            tree: tree,
          ),
        )
        .toList(growable: false);
    if (affectedTrees.isEmpty) {
      return _redirectTargets(snapshot, preferredTree);
    }
    final candidateTree = affectedTrees.firstWhere(
      (tree) => p.equals(tree.path, preferredTree.path),
      orElse: () => affectedTrees.first,
    );
    return _redirectTargets(snapshot, candidateTree)
        .where(
          (candidate) => affectedTrees.every(
            (tree) =>
                _elementsTargetingPath(
                  snapshot,
                  tree.document,
                  candidate.topicPath,
                  tree: tree,
                ).length ==
                1,
          ),
        )
        .toList(growable: false);
  }

  List<WritersideTopicRedirectTarget> _resolvedRedirectTargets(
    _RemovalSnapshot snapshot,
    _TreeSnapshot tree,
  ) {
    final instance = tree.owner.instances
        .where((candidate) => p.equals(candidate.sourceTreePath, tree.path))
        .firstOrNull;
    if (instance == null) return const [];
    final presenter = WritersideTocPresenter(
      module: tree.owner,
      instance: instance,
      modulesByOrigin: snapshot.project.modulesByOrigin,
    );
    final result = <WritersideTopicRedirectTarget>[];
    final seen = <String>{};
    for (final node in instance.navigationTocRoots.expand(
      (root) => root.flatten(),
    )) {
      if (!node.canEditStructure ||
          !p.equals(node.sourceTreePath!, tree.path) ||
          node.sourceTocPath == null) {
        continue;
      }
      final topic = presenter.present(node).topic;
      if (topic == null ||
          p.equals(topic.filePath, snapshot.topic.filePath) ||
          !seen.add(normalizePath(topic.filePath))) {
        continue;
      }
      result.add(
        WritersideTopicRedirectTarget(
          topicPath: topic.filePath,
          topicFileName: topic.fileName,
          label: topic.title?.trim().isNotEmpty == true
              ? topic.title!.trim()
              : topic.fileName,
          treePath: tree.path,
          nodePath: node.sourceTocPath!,
        ),
      );
    }
    return result;
  }

  List<WritersideTopicRedirectTarget> _redirectTargets(
    _RemovalSnapshot snapshot,
    _TreeSnapshot tree,
  ) {
    final result = <WritersideTopicRedirectTarget>[];
    final seen = <String>{};
    for (final entry in _tocEntries(tree.document.rootElement)) {
      final reference = _tocReference(entry.element);
      if (reference == null) {
        continue;
      }
      final owner = entry.element.getAttribute('origin') == null
          ? tree.owner
          : snapshot.project.modulesByOrigin[entry.element.getAttribute(
              'origin',
            )];
      final matches = owner?.topicsMatchingReference(reference) ?? const [];
      if (matches.length != 1) {
        continue;
      }
      final topic = matches.single;
      final topicPath = normalizePath(topic.filePath);
      if (p.equals(topicPath, snapshot.topic.filePath) ||
          !seen.add(topicPath)) {
        continue;
      }
      result.add(
        WritersideTopicRedirectTarget(
          topicPath: topicPath,
          topicFileName: topic.fileName,
          label: topic.title?.trim().isNotEmpty == true
              ? topic.title!.trim()
              : topic.fileName,
          treePath: tree.path,
          nodePath: entry.path,
        ),
      );
    }
    return result;
  }

  List<XmlElement> _elementsTargetingPath(
    _RemovalSnapshot snapshot,
    XmlDocument document,
    String topicPath, {
    required _TreeSnapshot tree,
  }) => document
      .findAllElements('toc-element')
      .where(
        (element) => _elementTargets(snapshot, element, topicPath, tree: tree),
      )
      .toList(growable: false);

  bool _documentContainsTarget(
    _RemovalSnapshot snapshot,
    XmlDocument document,
    String topicPath, {
    required _TreeSnapshot tree,
  }) => document
      .findAllElements('toc-element')
      .any(
        (element) => _elementTargets(snapshot, element, topicPath, tree: tree),
      );

  Set<String> _acceptedWebFileNames(
    _RemovalSnapshot snapshot,
    XmlElement element, {
    required String treePath,
  }) {
    final result = _directlyAcceptedWebFileNames(element);
    final references =
        (element.getAttribute('accepts-web-file-names-ref') ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty);
    for (final reference in references) {
      final owner = snapshot.trees[normalizePath(treePath)]?.owner;
      result.addAll(
        snapshot.redirectRules[owner?.rootPath]?[reference] ?? const <String>{},
      );
    }
    return result;
  }

  bool _resolvedInstanceHasRedirectConflict(
    _RemovalSnapshot snapshot, {
    required String treePath,
    required String webFileName,
    required String redirectTopicPath,
  }) {
    final tree = snapshot.trees[normalizePath(treePath)];
    if (tree == null) return true;
    final instance = tree.owner.instances
        .where((candidate) => p.equals(candidate.sourceTreePath, tree.path))
        .firstOrNull;
    if (instance == null) return false;
    final presenter = WritersideTocPresenter(
      module: tree.owner,
      instance: instance,
      modulesByOrigin: snapshot.project.modulesByOrigin,
    );
    for (final node in instance.navigationTocRoots.expand(
      (root) => root.flatten(),
    )) {
      final topic = presenter.present(node).topic;
      if (topic != null &&
          (p.equals(topic.filePath, snapshot.topic.filePath) ||
              p.equals(topic.filePath, redirectTopicPath))) {
        continue;
      }
      final names = <String>{
        ...(node.acceptsWebFileNames ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      };
      final sourceTree = node.sourceTreePath == null
          ? null
          : snapshot.trees[normalizePath(node.sourceTreePath!)];
      final rules = snapshot
          .redirectRules[sourceTree?.owner.rootPath ?? tree.owner.rootPath];
      for (final reference
          in (node.acceptsWebFileNamesRef ?? '')
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)) {
        names.addAll(rules?[reference] ?? const <String>{});
      }
      if (names.contains(webFileName)) return true;
      if (topic != null &&
          _effectiveWebFileName(snapshot, tree.path, topic: topic) ==
              webFileName) {
        return true;
      }
    }
    return false;
  }

  bool _elementPublishesWebFileName(
    _RemovalSnapshot snapshot,
    XmlElement element,
    String webFileName, {
    required String treePath,
  }) {
    final reference = _tocReference(element);
    if (reference == null) {
      return false;
    }
    final tree = snapshot.trees[normalizePath(treePath)]!;
    final owner = element.getAttribute('origin') == null
        ? tree.owner
        : snapshot.project.modulesByOrigin[element.getAttribute('origin')];
    final matches = owner?.topicsMatchingReference(reference) ?? const [];
    if (matches.length != 1) {
      return false;
    }
    return _effectiveWebFileName(snapshot, treePath, topic: matches.single) ==
        webFileName;
  }

  String _effectiveWebFileName(
    _RemovalSnapshot snapshot,
    String? treePath, {
    WritersideTopic? topic,
  }) {
    final tree = treePath == null
        ? null
        : snapshot.trees[normalizePath(treePath)];
    final instance = tree?.owner.instances
        .where(
          (candidate) =>
              treePath != null && p.equals(candidate.sourceTreePath, treePath),
        )
        .firstOrNull;
    final effectiveInstance =
        instance ??
        tree?.owner.instances.where((value) => !value.isLibrary).firstOrNull ??
        tree?.owner.instances.firstOrNull;
    final target = topic ?? snapshot.topic;
    final targetOwner =
        snapshot.project.topicOwnerForPath(target.filePath) ?? snapshot.module;
    if (effectiveInstance == null) {
      return WritersideWebFileNameResolver.defaultName(
        target.fileName,
        disablePreprocessing:
            targetOwner.config.settings.disableWebNamePreprocessing == true,
      );
    }
    return const WritersideWebFileNameResolver()
        .resolve(
          module: targetOwner,
          topic: target,
          instance: effectiveInstance,
          modulesByOrigin: snapshot.project.modulesByOrigin,
        )
        .value;
  }

  int _removeAndPromote(XmlElement element) {
    final parent = element.parent;
    if (parent == null) {
      throw const BusyMarkException('writerside.toc.path-invalid');
    }
    final index = parent.children.indexOf(element);
    final children = element.childElements
        .where(_isTocElement)
        .map((child) => child.copy())
        .toList();
    parent.children.removeAt(index);
    parent.children.insertAll(index, children);
    return children.length;
  }

  Future<void> _ensureExpectedState(
    _RemovalSnapshot snapshot,
    List<_SourceEdit> edits,
  ) async {
    final edited = {for (final edit in edits) edit.path: edit.updated};
    for (final entry in snapshot.sources.entries) {
      final expected = edited[entry.key] ?? entry.value;
      final resolution = await resolveAnchoredPath(
        snapshot.anchor,
        entry.key,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.file ||
          await File(resolution.path).readAsString() != expected) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': entry.key},
        );
      }
    }
  }

  Future<void> _replaceAtomically(
    CanonicalPathAnchor anchor,
    String path,
    String source, {
    required String expected,
    void Function()? validateBeforeCommit,
  }) async {
    final resolution = await resolveAnchoredPath(
      anchor,
      path,
      allowRoot: false,
    );
    if (resolution.type != FileSystemEntityType.file ||
        await File(resolution.path).readAsString() != expected) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': path},
      );
    }
    final stat = await File(path).stat();
    File? temporary;
    try {
      for (var attempt = 0; attempt < 100; attempt += 1) {
        final candidate = File(
          p.join(
            p.dirname(path),
            '.${p.basename(path)}.busymark-safe-delete-'
            '$pid-${DateTime.now().microsecondsSinceEpoch}-$attempt',
          ),
        );
        try {
          temporary = await candidate.create(exclusive: true);
          break;
        } on FileSystemException {
          continue;
        }
      }
      if (temporary == null) {
        throw FileSystemException('Unable to create a temporary file.', path);
      }
      await temporary.writeAsString(source, flush: true);
      if (!Platform.isWindows) {
        final mode = (stat.mode & 0xfff).toRadixString(8);
        final chmod = await Process.run('chmod', [mode, temporary.path]);
        if (chmod.exitCode != 0) {
          throw FileSystemException(
            'Unable to preserve file permissions: ${chmod.stderr}',
            path,
          );
        }
      }
      final checked = await resolveAnchoredPath(anchor, path, allowRoot: false);
      if (checked.type != FileSystemEntityType.file ||
          await File(checked.path).readAsString() != expected) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': path},
        );
      }
      validateBeforeCommit?.call();
      final atomicApi = LinuxAtomicFileApi.instance;
      if (atomicApi.isAvailable) {
        final exchangeError = atomicApi.exchange(temporary.path, checked.path);
        if (exchangeError != null) {
          throw FileSystemException(
            'Unable to atomically exchange the staged file '
            '(errno $exchangeError).',
            path,
          );
        }
        final replacedType = await FileSystemEntity.type(
          temporary.path,
          followLinks: false,
        );
        final replacedStat = replacedType == FileSystemEntityType.file
            ? await temporary.stat()
            : null;
        final replacedMatches =
            replacedType == FileSystemEntityType.file &&
            replacedStat != null &&
            (replacedStat.mode & 0xfff) == (stat.mode & 0xfff) &&
            await temporary.readAsString() == expected;
        if (!replacedMatches) {
          final restoreError = atomicApi.exchange(temporary.path, checked.path);
          if (restoreError != null) {
            throw BusyMarkException(
              'writerside.topic-removal.rollback-failed',
              args: {'paths': '${temporary.path}, ${checked.path}'},
            );
          }
          throw BusyMarkException(
            'writerside.topic-file.tree-changed',
            args: {'path': path},
          );
        }
        try {
          await temporary.delete();
        } on Object catch (error, stackTrace) {
          final restoreError = atomicApi.exchange(temporary.path, checked.path);
          if (restoreError != null) {
            throw BusyMarkException(
              'writerside.topic-removal.rollback-failed',
              args: {'paths': '${temporary.path}, ${checked.path}'},
            );
          }
          Error.throwWithStackTrace(error, stackTrace);
        }
        temporary = null;
        return;
      }
      await temporary.rename(checked.path);
      temporary = null;
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<void> _deleteExpectedFile(
    CanonicalPathAnchor anchor,
    String path, {
    required String expected,
    void Function()? validateBeforeCommit,
  }) async {
    final resolution = await resolveAnchoredPath(
      anchor,
      path,
      allowRoot: false,
    );
    if (resolution.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic-file.tree-changed',
        args: {'path': path},
      );
    }
    File? quarantined;
    try {
      for (var attempt = 0; attempt < 100; attempt += 1) {
        final candidate = File(
          p.join(
            p.dirname(resolution.path),
            '.${p.basename(resolution.path)}.busymark-safe-delete-quarantine-'
            '$pid-${DateTime.now().microsecondsSinceEpoch}-$attempt',
          ),
        );
        if (await FileSystemEntity.type(candidate.path, followLinks: false) !=
            FileSystemEntityType.notFound) {
          continue;
        }
        try {
          validateBeforeCommit?.call();
          quarantined = await File(resolution.path).rename(candidate.path);
          break;
        } on FileSystemException {
          final current = await resolveAnchoredPath(
            anchor,
            path,
            allowRoot: false,
          );
          if (current.type != FileSystemEntityType.file) {
            rethrow;
          }
        }
      }
      if (quarantined == null) {
        throw FileSystemException('Unable to quarantine the topic file.', path);
      }
      if (await quarantined.readAsString() != expected) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': path},
        );
      }
      if (await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw BusyMarkException(
          'writerside.topic-file.tree-changed',
          args: {'path': path},
        );
      }
      validateBeforeCommit?.call();
      await quarantined.delete();
      quarantined = null;
    } on Object catch (error, stackTrace) {
      String? recoveryPath;
      if (quarantined != null && await quarantined.exists()) {
        if (await FileSystemEntity.type(path, followLinks: false) ==
            FileSystemEntityType.notFound) {
          try {
            await quarantined.rename(path);
            quarantined = null;
          } on Object {
            // Keep the quarantined file recoverable rather than overwrite data.
          }
        }
        if (quarantined != null) {
          recoveryPath = quarantined.path;
        }
      }
      if (recoveryPath != null) {
        throw BusyMarkException(
          'writerside.topic-removal.rollback-failed',
          args: {'paths': recoveryPath},
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class _RemovalSnapshot {
  const _RemovalSnapshot({
    required this.anchor,
    required this.project,
    required this.module,
    required this.topic,
    required this.sources,
    required this.trees,
    required this.redirectRules,
    required this.moduleRoots,
    required this.fingerprint,
  });

  final CanonicalPathAnchor anchor;
  final WritersideProject project;
  final WritersideModule module;
  final WritersideTopic topic;
  final Map<String, String> sources;
  final Map<String, _TreeSnapshot> trees;
  final Map<String, Map<String, Set<String>>> redirectRules;
  final List<String> moduleRoots;
  final String fingerprint;
}

class _TreeSnapshot {
  const _TreeSnapshot({
    required this.path,
    required this.source,
    required this.document,
    required this.owner,
  });

  final String path;
  final String source;
  final XmlDocument document;
  final WritersideModule owner;
}

class _TextReplacement {
  const _TextReplacement(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;
}

class _TocEntry {
  const _TocEntry(this.element, this.path);

  final XmlElement element;
  final List<int> path;
}

class _SourceEdit {
  const _SourceEdit({
    required this.path,
    required this.original,
    required this.updated,
  });

  final String path;
  final String original;
  final String updated;
}

class _ReferenceExpansion {
  _ReferenceExpansion({
    required Set<String> values,
    required Set<String> patterns,
    required this.unresolved,
  }) : values = Set.unmodifiable(values),
       patterns = Set.unmodifiable(patterns);

  final Set<String> values;
  final Set<String> patterns;
  final bool unresolved;
}

Iterable<_TocEntry> _tocEntries(XmlElement root) sync* {
  Iterable<_TocEntry> visit(XmlElement parent, List<int> parentPath) sync* {
    final children = parent.childElements.where(_isTocElement).toList();
    for (var index = 0; index < children.length; index += 1) {
      final path = [...parentPath, index];
      yield _TocEntry(children[index], path);
      yield* visit(children[index], path);
    }
  }

  yield* visit(root, const []);
}

XmlElement _elementAtPath(XmlElement root, List<int> path) {
  var current = root;
  for (final index in path) {
    final children = current.childElements.where(_isTocElement).toList();
    if (index < 0 || index >= children.length) {
      throw BusyMarkException(
        'writerside.toc.path-invalid',
        args: {'path': path.join('/'), 'role': 'source'},
      );
    }
    current = children[index];
  }
  return current;
}

bool _isTocElement(XmlElement element) => element.name.local == 'toc-element';

bool _samePath(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

String? _tocReference(XmlElement element) {
  final topic = element.getAttribute('topic')?.trim();
  if (topic != null && topic.isNotEmpty) return topic;
  final reference = element.getAttribute('ref')?.trim();
  return reference == null || reference.isEmpty ? null : reference;
}

String _treeNodeKey(String filePath, int offset) =>
    '${normalizePath(filePath)}:$offset';

WritersideModule? _mostSpecificModuleForPath(
  Iterable<WritersideModule> modules,
  String filePath,
) {
  final path = normalizePath(filePath);
  final matches = modules.where((module) {
    final root = normalizePath(module.rootPath);
    return p.equals(root, path) || p.isWithin(root, path);
  }).toList()..sort((a, b) => b.rootPath.length.compareTo(a.rootPath.length));
  return matches.firstOrNull;
}

int _comparePathsForRemoval(List<int> first, List<int> second) {
  final length = first.length < second.length ? first.length : second.length;
  for (var index = 0; index < length; index += 1) {
    final compared = first[index].compareTo(second[index]);
    if (compared != 0) return compared;
  }
  return first.length.compareTo(second.length);
}

bool _sameStringList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    if (!p.equals(first[index], second[index])) return false;
  }
  return true;
}

String _referenceWithoutAnchor(String destination) =>
    destination.split('#').first.split('?').first;

String _xmlSource(XmlDocument document) =>
    '${document.toXmlString(pretty: true, indent: '  ')}\n';

String _fingerprint(Map<String, String> sources) {
  final paths = sources.keys.toList()..sort();
  final data = StringBuffer();
  for (final path in paths) {
    data
      ..write(path)
      ..write('\u0000')
      ..write(sources[path])
      ..write('\u0000');
  }
  return crypto.sha256.convert(utf8.encode('$data')).toString();
}

String _decodeWritersideVariableEscapes(String value) =>
    value.replaceAll(RegExp('%25', caseSensitive: false), '%');

Set<String> _directlyAcceptedWebFileNames(XmlElement element) =>
    (element.getAttribute('accepts-web-file-names') ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();

final RegExp _markdownLinkPattern = RegExp(
  r'''(?<!!)\[([^\]]*)\]\(\s*(<[^>]+>|[^\s)]+)(?:\s+["'][^"']*["'])?\s*\)''',
);
final RegExp _xmlAnchorPattern = RegExp(
  r'''<a\b(?=[^>]*\bhref\s*=\s*["'](?<href>[^"']+)["'])[^>]*>(?<body>.*?)</a\s*>''',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _writersideVariableReference = RegExp(
  r'(?<!\\)%([A-Za-z_][A-Za-z0-9_.-]*)%',
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
