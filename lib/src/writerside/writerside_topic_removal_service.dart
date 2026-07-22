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

enum WritersideTopicRemovalMode { removeFromInstance, safeDeleteFile }

enum WritersideTopicUsageKind { tocElement, startPage, topicLink, include }

class WritersideTopicUsage {
  const WritersideTopicUsage({
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    required this.reference,
    required this.relevant,
    required this.canUpdateAutomatically,
  });

  final WritersideTopicUsageKind kind;
  final String filePath;
  final int line;
  final int column;
  final String reference;
  final bool relevant;
  final bool canUpdateAutomatically;
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
    required this.moduleRoot,
    required this.topicPath,
    required this.topicFileName,
    required this.topicTitle,
    required this.oldWebFileName,
    required this.selectedTreePath,
    required List<int>? selectedNodePath,
    required this.childCount,
    required this.isStartPage,
    required List<WritersideTopicUsage> usages,
    required List<WritersideTopicRedirectTarget> redirectTargets,
    required this.fingerprint,
  }) : selectedNodePath = selectedNodePath == null
           ? null
           : List.unmodifiable(selectedNodePath),
       usages = List.unmodifiable(usages),
       redirectTargets = List.unmodifiable(redirectTargets);

  final WritersideTopicRemovalMode mode;
  final String moduleRoot;
  final String topicPath;
  final String topicFileName;
  final String? topicTitle;
  final String oldWebFileName;
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
                usage.kind == WritersideTopicUsageKind.include,
          WritersideTopicRemovalMode.safeDeleteFile =>
            usage.kind == WritersideTopicUsageKind.startPage ||
                (usage.kind == WritersideTopicUsageKind.tocElement &&
                    !usage.canUpdateAutomatically) ||
                usage.kind == WritersideTopicUsageKind.topicLink ||
                usage.kind == WritersideTopicUsageKind.include,
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
/// Analysis snapshots every topic source and every `.tree` file below the
/// module root. Apply rebuilds that snapshot and refuses to mutate anything if
/// any input changed, so a dialog can never authorize a stale refactoring.
class WritersideTopicRemovalService {
  const WritersideTopicRemovalService({
    this.moduleService = const WritersideModuleService(),
  });

  final WritersideModuleService moduleService;

  Future<WritersideTopicRemovalAnalysis> analyze({
    required WritersideModule module,
    required String topicPath,
    required WritersideTopicRemovalMode mode,
    String? selectedTreePath,
    List<int>? selectedNodePath,
  }) async {
    final snapshot = await _snapshot(module.rootPath, topicPath);
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
      final selectedReference = selectedElement.getAttribute('topic');
      if (selectedReference == null || !_targets(snapshot, selectedReference)) {
        throw BusyMarkException(
          'writerside.toc.path-invalid',
          args: {'path': selectedNodePath.join('/'), 'role': 'source'},
        );
      }
    }

    final selectedTopicPaths = selectedTree == null
        ? const <String>{}
        : _topicsInTree(snapshot, snapshot.trees[selectedTree]!);
    final usages = <WritersideTopicUsage>[];
    var childCount = 0;
    for (final tree in snapshot.trees.values) {
      final root = tree.document.rootElement;
      final startPage = root.getAttribute('start-page');
      if (startPage != null && _couldTarget(snapshot, startPage)) {
        usages.add(
          _treeUsage(
            tree,
            kind: WritersideTopicUsageKind.startPage,
            reference: startPage,
            relevant:
                mode == WritersideTopicRemovalMode.safeDeleteFile ||
                (selectedTree != null && p.equals(tree.path, selectedTree)),
            canUpdateAutomatically: false,
          ),
        );
      }
      for (final entry in _tocEntries(root)) {
        final reference = entry.element.getAttribute('topic');
        if (reference == null || !_couldTarget(snapshot, reference)) {
          continue;
        }
        final selectedOccurrence =
            selectedTree != null &&
            p.equals(tree.path, selectedTree) &&
            (selectedNodePath == null ||
                _samePath(entry.path, selectedNodePath));
        usages.add(
          _treeUsage(
            tree,
            kind: WritersideTopicUsageKind.tocElement,
            reference: reference,
            relevant:
                mode == WritersideTopicRemovalMode.safeDeleteFile ||
                selectedOccurrence,
            canUpdateAutomatically: _targets(snapshot, reference),
          ),
        );
        final directChildren = entry.element.childElements
            .where(_isTocElement)
            .length;
        if (mode == WritersideTopicRemovalMode.safeDeleteFile &&
            _targets(snapshot, reference)) {
          childCount += directChildren;
        } else if (selectedOccurrence) {
          childCount = directChildren;
        }
      }
    }

    for (final sourceTopic in snapshot.module.topics) {
      if (p.equals(sourceTopic.filePath, snapshot.topic.filePath)) {
        continue;
      }
      final relevantSource =
          mode == WritersideTopicRemovalMode.safeDeleteFile ||
          selectedTopicPaths.contains(normalizePath(sourceTopic.filePath));
      final source = snapshot.sources[normalizePath(sourceTopic.filePath)]!;
      for (final link in sourceTopic.links) {
        if (hasUriScheme(link.destination) ||
            !_couldTarget(
              snapshot,
              _referenceWithoutAnchor(link.destination),
              fromTopic: sourceTopic,
            )) {
          continue;
        }
        usages.add(
          WritersideTopicUsage(
            kind: WritersideTopicUsageKind.topicLink,
            filePath: sourceTopic.filePath,
            line: link.span.startLine,
            column: link.span.startColumn,
            reference: link.destination,
            relevant: relevantSource,
            canUpdateAutomatically: _canRewriteLink(
              snapshot,
              sourceTopic,
              source,
              link.destination,
            ),
          ),
        );
      }
      for (final include in sourceTopic.includes) {
        final reference = include.from;
        if (reference == null ||
            !_couldTarget(snapshot, reference, fromTopic: sourceTopic)) {
          continue;
        }
        usages.add(
          WritersideTopicUsage(
            kind: WritersideTopicUsageKind.include,
            filePath: sourceTopic.filePath,
            line: include.span.startLine,
            column: include.span.startColumn,
            reference: reference,
            relevant: relevantSource,
            canUpdateAutomatically: _canRewriteInclude(
              snapshot,
              sourceTopic,
              source,
              reference,
            ),
          ),
        );
      }
    }

    final preferredTree = selectedTree ?? _preferredTree(snapshot);
    return WritersideTopicRemovalAnalysis(
      mode: mode,
      moduleRoot: snapshot.anchor.rootPath,
      topicPath: snapshot.topic.filePath,
      topicFileName: snapshot.topic.fileName,
      topicTitle: snapshot.topic.title,
      oldWebFileName: _oldWebFileName(
        snapshot.topic,
        disablePreprocessing:
            snapshot.module.config.settings.disableWebNamePreprocessing == true,
      ),
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
    );
  }

  Future<WritersideTopicRemovalResult> apply(
    WritersideTopicRemovalRequest request,
  ) async {
    final analysis = request.analysis;
    final snapshot = await _snapshot(analysis.moduleRoot, analysis.topicPath);
    if (snapshot.fingerprint != analysis.fingerprint) {
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
      )) {
        throw BusyMarkException(
          'writerside.toc.path-invalid',
          args: {'path': nodePath.join('/'), 'role': 'source'},
        );
      }
    }
    final removedElements = Set<XmlElement>.identity();
    if (selectedRemovalElement != null) {
      removedElements.add(selectedRemovalElement);
    } else {
      for (final document in treeDocuments.values) {
        removedElements.addAll(
          document
              .findAllElements('toc-element')
              .where(
                (element) =>
                    _elementTargets(snapshot, element, snapshot.topic.filePath),
              ),
        );
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
        if (!_elementTargets(snapshot, element, redirect.topicPath)) {
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
        final conflictingRedirect = document
            .findAllElements('toc-element')
            .any(
              (element) =>
                  !identical(element, entry.value) &&
                  !removedElements.contains(element) &&
                  (_acceptedWebFileNames(
                        snapshot,
                        element,
                      ).contains(analysis.oldWebFileName) ||
                      _elementPublishesWebFileName(
                        snapshot,
                        element,
                        analysis.oldWebFileName,
                      )),
            );
        if (conflictingRedirect) {
          throw const BusyMarkException(
            'writerside.topic-removal.redirect-invalid',
          );
        }
      }
      for (final entry in redirectElements.entries) {
        if (_acceptedWebFileNames(
              snapshot,
              entry.value,
            ).contains(analysis.oldWebFileName) ||
            _elementPublishesWebFileName(
              snapshot,
              entry.value,
              analysis.oldWebFileName,
            )) {
          continue;
        }
        final oldNames =
            (entry.value.getAttribute('accepts-web-file-names') ?? '')
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList();
        if (!oldNames.contains(analysis.oldWebFileName)) {
          oldNames.add(analysis.oldWebFileName);
          entry.value.setAttribute(
            'accepts-web-file-names',
            oldNames.join(','),
          );
          changedTreePaths.add(entry.key);
          redirectAdded = true;
        }
      }
    }

    if (selectedRemovalElement != null) {
      promotedChildren += _removeAndPromote(selectedRemovalElement);
      changedTreePaths.add(normalizePath(analysis.selectedTreePath!));
    } else {
      for (final entry in treeDocuments.entries) {
        if (!_documentContainsTarget(
          snapshot,
          entry.value,
          snapshot.topic.filePath,
        )) {
          continue;
        }
        promotedChildren += _removeAllTargetEntries(
          snapshot,
          entry.value.rootElement,
        );
        changedTreePaths.add(entry.key);
      }
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
        final sourceTopic = snapshot.module.topics.firstWhere(
          (topic) => p.equals(topic.filePath, path),
        );
        final original = snapshot.sources[path]!;
        final updated = _rewriteTopicUsages(snapshot, sourceTopic, original);
        if (updated == original) {
          throw BusyMarkException(
            'writerside.topic-removal.usages-remain',
            args: {'path': path},
          );
        }
        if (_topicSourceStillReferencesTarget(snapshot, sourceTopic, updated)) {
          throw BusyMarkException(
            'writerside.topic-removal.usages-remain',
            args: {'path': path},
          );
        }
        updatedSources[path] = updated;
        updatedUsageFiles.add(path);
      }
    }

    final sourceUsageRemains = _topicSourcesCouldContainTarget(
      snapshot,
      updatedSources,
    );
    if (analysis.mode == WritersideTopicRemovalMode.safeDeleteFile &&
        (_treeDocumentsCouldContainTarget(snapshot, treeDocuments.values) ||
            sourceUsageRemains)) {
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
    try {
      for (final edit in edits) {
        await _replaceAtomically(
          snapshot.anchor,
          edit.path,
          edit.updated,
          expected: edit.original,
        );
        applied.add(edit);
      }
      await _ensureExpectedState(snapshot, edits);
      if (analysis.mode == WritersideTopicRemovalMode.safeDeleteFile) {
        await _deleteExpectedFile(
          snapshot.anchor,
          snapshot.topic.filePath,
          expected: snapshot.sources[snapshot.topic.filePath]!,
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
        : !_treeDocumentsCouldContainTarget(snapshot, treeDocuments.values) &&
              !sourceUsageRemains;
    return WritersideTopicRemovalResult(
      deletedFile: analysis.mode == WritersideTopicRemovalMode.safeDeleteFile,
      orphaned: orphaned,
      promotedChildren: promotedChildren,
      redirectAdded: redirectAdded,
      updatedUsageFiles: List.unmodifiable(updatedUsageFiles),
    );
  }

  Future<_RemovalSnapshot> _snapshot(
    String moduleRoot,
    String requestedTopicPath,
  ) async {
    final anchor = await captureCanonicalDirectoryAnchor(moduleRoot);
    final module = await moduleService.load(anchor.rootPath);
    final incompleteModule = module.diagnostics.where(
      (diagnostic) =>
          diagnostic.code.startsWith('workspace.scan.') ||
          diagnostic.code == 'writerside.topic.read-failed' ||
          diagnostic.code == 'writerside.topic.invalid-xml' ||
          diagnostic.code == 'writerside.variables.invalid-xml' ||
          diagnostic.code == 'writerside.config.invalid-xml' ||
          diagnostic.code == 'writerside.config.invalid-root',
    );
    if (incompleteModule.isNotEmpty) {
      final diagnostic = incompleteModule.first;
      throw BusyMarkException(
        'writerside.topic-removal.scan-failed',
        args: {'path': diagnostic.filePath, 'error': diagnostic.code},
      );
    }
    final safeTopicPath = _canonicalInputPath(anchor, requestedTopicPath);
    WritersideTopic? topic;
    for (final candidate in module.topics) {
      if (p.equals(normalizePath(candidate.filePath), safeTopicPath)) {
        topic = candidate;
        break;
      }
    }
    if (topic == null) {
      throw BusyMarkException(
        'writerside.topic-file.not-found',
        args: {'path': safeTopicPath},
      );
    }

    final sources = <String, String>{};
    final configPath = _canonicalInputPath(anchor, module.config.filePath);
    sources[configPath] = await _readRegularFile(anchor, configPath);
    final variablesFile = module.config.varsFile;
    if (variablesFile != null) {
      final variablesPath = _canonicalInputPath(
        anchor,
        p.join(anchor.rootPath, variablesFile),
      );
      sources[variablesPath] = await _readRegularFile(anchor, variablesPath);
    }
    for (final sourceTopic in module.topics) {
      final path = _canonicalInputPath(anchor, sourceTopic.filePath);
      sources[path] = await _readRegularFile(anchor, path);
    }

    final redirectRules = <String, Set<String>>{};
    final redirectRulesPath = _canonicalInputPath(
      anchor,
      p.join(anchor.rootPath, 'redirection-rules.xml'),
    );
    if (await FileSystemEntity.type(redirectRulesPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      try {
        final source = await _readRegularFile(anchor, redirectRulesPath);
        final document = XmlDocument.parse(source);
        sources[redirectRulesPath] = source;
        for (final rule in document.findAllElements('rule')) {
          final id = rule.getAttribute('id')?.trim();
          if (id == null || id.isEmpty) {
            continue;
          }
          final accepted = redirectRules.putIfAbsent(id, () => <String>{});
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
        options: moduleService.scanOptions,
      );
      if (scan.diagnostics.isNotEmpty) {
        final diagnostic = scan.diagnostics.first;
        throw BusyMarkException(
          'writerside.topic-removal.scan-failed',
          args: {'path': diagnostic.filePath, 'error': diagnostic.code},
        );
      }
      for (final entity in scan.entities) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.tree') {
          continue;
        }
        final path = _canonicalInputPath(anchor, entity.path);
        final source = await _readRegularFile(anchor, path);
        final document = XmlDocument.parse(source);
        if (document.rootElement.name.local != 'instance-profile') {
          throw FormatException('.tree root must be <instance-profile>.', path);
        }
        sources[path] = source;
        trees[path] = _TreeSnapshot(
          path: path,
          source: source,
          document: document,
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
    for (final configured in module.config.instanceSources) {
      final configuredPath = _canonicalInputPath(
        anchor,
        p.join(anchor.rootPath, configured),
      );
      if (!trees.containsKey(configuredPath)) {
        throw BusyMarkException(
          'writerside.topic-file.tree-missing',
          args: {'path': configuredPath},
        );
      }
    }
    return _RemovalSnapshot(
      anchor: anchor,
      module: module,
      topic: topic,
      sources: Map.unmodifiable(sources),
      trees: Map.unmodifiable(trees),
      redirectRules: Map.unmodifiable({
        for (final entry in redirectRules.entries)
          entry.key: Set.unmodifiable(entry.value),
      }),
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
    String path,
  ) async {
    try {
      final resolution = await resolveAnchoredPath(
        anchor,
        path,
        allowRoot: false,
      );
      if (resolution.type != FileSystemEntityType.file) {
        throw const FileSystemException('Not a regular file');
      }
      return File(resolution.path).readAsString();
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
  }) {
    final expansion = _expandReference(snapshot, reference, fromTopic);
    if (expansion.unresolved || expansion.values.isEmpty) {
      return false;
    }
    for (final value in expansion.values) {
      final matches = snapshot.module.topicsMatchingReference(
        value,
        fromTopic: fromTopic,
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
  }) {
    final expansion = _expandReference(snapshot, reference, fromTopic);
    for (final value in expansion.values) {
      if (snapshot.module
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
    WritersideTopic? fromTopic,
  ) {
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
      final values = _variableValues(snapshot, match.group(1)!, fromTopic);
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
    WritersideTopic? fromTopic,
  ) {
    final configured = snapshot.module.variables
        .where((variable) => variable.name == name)
        .map((variable) => variable.value)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (configured.isNotEmpty) {
      return configured;
    }
    return switch (name) {
      'thisTopic' when fromTopic != null => {fromTopic.id},
      'currentId' => {
        for (final instance in snapshot.module.instances) instance.id,
      },
      'instance' => {
        for (final instance in snapshot.module.instances) instance.name,
      },
      'instance-lowercase' => {
        for (final instance in snapshot.module.instances)
          instance.name.toLowerCase(),
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
    String topicPath,
  ) {
    final reference = element.getAttribute('topic');
    if (reference == null) {
      return false;
    }
    final expansion = _expandReference(snapshot, reference, null);
    if (expansion.unresolved || expansion.values.isEmpty) {
      return false;
    }
    for (final value in expansion.values) {
      final matches = snapshot.module.topicsMatchingReference(value);
      if (matches.length != 1 ||
          !p.equals(matches.single.filePath, topicPath)) {
        return false;
      }
    }
    return true;
  }

  Set<String> _topicsInTree(_RemovalSnapshot snapshot, _TreeSnapshot tree) {
    final result = <String>{};
    final startPage = tree.document.rootElement.getAttribute('start-page');
    if (startPage != null) {
      final expansion = _expandReference(snapshot, startPage, null);
      for (final value in expansion.values) {
        for (final match in snapshot.module.topicsMatchingReference(value)) {
          result.add(normalizePath(match.filePath));
        }
      }
    }
    for (final element in tree.document.findAllElements('toc-element')) {
      final reference = element.getAttribute('topic');
      if (reference == null) {
        continue;
      }
      final expansion = _expandReference(snapshot, reference, null);
      for (final value in expansion.values) {
        final matches = snapshot.module.topicsMatchingReference(value);
        for (final match in matches) {
          result.add(normalizePath(match.filePath));
        }
      }
    }
    return result;
  }

  WritersideTopicUsage _treeUsage(
    _TreeSnapshot tree, {
    required WritersideTopicUsageKind kind,
    required String reference,
    required bool relevant,
    required bool canUpdateAutomatically,
  }) {
    final offset = tree.source.indexOf(reference);
    final span = SourceSpan.fromOffsets(
      filePath: tree.path,
      source: tree.source,
      startOffset: offset < 0 ? 0 : offset,
      endOffset: offset < 0 ? 0 : offset + reference.length,
    );
    return WritersideTopicUsage(
      kind: kind,
      filePath: tree.path,
      line: span.startLine,
      column: span.startColumn,
      reference: reference,
      relevant: relevant,
      canUpdateAutomatically: canUpdateAutomatically,
    );
  }

  String? _preferredTree(_RemovalSnapshot snapshot) {
    for (final configured in snapshot.module.config.instanceSources) {
      final candidate = normalizePath(
        p.join(snapshot.anchor.rootPath, configured),
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
      return _redirectTargets(snapshot, preferredTree);
    }
    final affectedTrees = snapshot.trees.values
        .where(
          (tree) => _documentContainsTarget(
            snapshot,
            tree.document,
            snapshot.topic.filePath,
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
                ).length ==
                1,
          ),
        )
        .toList(growable: false);
  }

  List<WritersideTopicRedirectTarget> _redirectTargets(
    _RemovalSnapshot snapshot,
    _TreeSnapshot tree,
  ) {
    final result = <WritersideTopicRedirectTarget>[];
    final seen = <String>{};
    for (final entry in _tocEntries(tree.document.rootElement)) {
      final reference = entry.element.getAttribute('topic');
      if (reference == null) {
        continue;
      }
      final matches = snapshot.module.topicsMatchingReference(reference);
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
    String topicPath,
  ) => document
      .findAllElements('toc-element')
      .where((element) => _elementTargets(snapshot, element, topicPath))
      .toList(growable: false);

  bool _documentContainsTarget(
    _RemovalSnapshot snapshot,
    XmlDocument document,
    String topicPath,
  ) => document
      .findAllElements('toc-element')
      .any((element) => _elementTargets(snapshot, element, topicPath));

  Set<String> _acceptedWebFileNames(
    _RemovalSnapshot snapshot,
    XmlElement element,
  ) {
    final result = _directlyAcceptedWebFileNames(element);
    final references =
        (element.getAttribute('accepts-web-file-names-ref') ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty);
    for (final reference in references) {
      result.addAll(snapshot.redirectRules[reference] ?? const <String>{});
    }
    return result;
  }

  bool _elementPublishesWebFileName(
    _RemovalSnapshot snapshot,
    XmlElement element,
    String webFileName,
  ) {
    final reference = element.getAttribute('topic');
    if (reference == null) {
      return false;
    }
    final matches = snapshot.module.topicsMatchingReference(reference);
    if (matches.length != 1) {
      return false;
    }
    return _oldWebFileName(
          matches.single,
          disablePreprocessing:
              snapshot.module.config.settings.disableWebNamePreprocessing ==
              true,
        ) ==
        webFileName;
  }

  bool _canRewriteLink(
    _RemovalSnapshot snapshot,
    WritersideTopic topic,
    String source,
    String destination,
  ) {
    if (topic.format == WritersideTopicFormat.xml) {
      try {
        return XmlDocument.parse(source)
            .findAllElements('a')
            .any(
              (element) =>
                  element.getAttribute('href') == destination &&
                  _targets(
                    snapshot,
                    _referenceWithoutAnchor(destination),
                    fromTopic: topic,
                  ),
            );
      } on Object {
        return false;
      }
    }
    return _markdownLinkPattern.allMatches(source).any((match) {
      final found = _unquoteDestination(match.group(2)!);
      return _sameWritersideReference(found, destination) &&
          _targets(snapshot, _referenceWithoutAnchor(found), fromTopic: topic);
    });
  }

  bool _canRewriteInclude(
    _RemovalSnapshot snapshot,
    WritersideTopic topic,
    String source,
    String reference,
  ) {
    if (!_targets(snapshot, reference, fromTopic: topic)) {
      return false;
    }
    if (topic.format == WritersideTopicFormat.xml) {
      try {
        return XmlDocument.parse(source)
            .findAllElements('include')
            .any((element) => element.getAttribute('from') == reference);
      } on Object {
        return false;
      }
    }
    return _includePattern
        .allMatches(source)
        .any((match) => _attributeValue(match.group(0)!, 'from') == reference);
  }

  String _rewriteTopicUsages(
    _RemovalSnapshot snapshot,
    WritersideTopic topic,
    String source,
  ) {
    if (topic.format == WritersideTopicFormat.xml) {
      final document = XmlDocument.parse(source);
      for (final anchor in document.findAllElements('a').toList()) {
        final href = anchor.getAttribute('href');
        if (href == null ||
            !_targets(
              snapshot,
              _referenceWithoutAnchor(href),
              fromTopic: topic,
            )) {
          continue;
        }
        final parent = anchor.parent;
        if (parent == null) {
          continue;
        }
        final index = parent.children.indexOf(anchor);
        final promoted = anchor.children.map((node) => node.copy()).toList();
        parent.children.removeAt(index);
        parent.children.insertAll(index, promoted);
      }
      for (final include in document.findAllElements('include').toList()) {
        final from = include.getAttribute('from');
        if (from != null && _targets(snapshot, from, fromTopic: topic)) {
          include.parent?.children.remove(include);
        }
      }
      return _xmlSource(document);
    }

    var updated = source.replaceAllMapped(_markdownLinkPattern, (match) {
      final destination = _unquoteDestination(match.group(2)!);
      if (!_targets(
        snapshot,
        _referenceWithoutAnchor(destination),
        fromTopic: topic,
      )) {
        return match.group(0)!;
      }
      return match.group(1)!;
    });
    updated = updated.replaceAllMapped(_xmlAnchorPattern, (match) {
      final href = match.group(1)!;
      if (!_targets(
        snapshot,
        _referenceWithoutAnchor(href),
        fromTopic: topic,
      )) {
        return match.group(0)!;
      }
      return match.group(2)!;
    });
    updated = updated.replaceAllMapped(_includePattern, (match) {
      final element = match.group(0)!;
      final from = _attributeValue(element, 'from');
      return from != null && _targets(snapshot, from, fromTopic: topic)
          ? ''
          : element;
    });
    return updated;
  }

  bool _topicSourceStillReferencesTarget(
    _RemovalSnapshot snapshot,
    WritersideTopic topic,
    String source,
  ) {
    final parsed = switch (topic.format) {
      WritersideTopicFormat.markdown => moduleService.topicParser.parseMarkdown(
        filePath: topic.filePath,
        source: source,
        topicsRoot: topic.topicRoot,
      ),
      WritersideTopicFormat.xml => moduleService.topicParser.parseXml(
        filePath: topic.filePath,
        source: source,
        topicsRoot: topic.topicRoot,
      ),
    };
    return parsed.links.any(
          (link) =>
              !hasUriScheme(link.destination) &&
              _couldTarget(
                snapshot,
                _referenceWithoutAnchor(link.destination),
                fromTopic: topic,
              ),
        ) ||
        parsed.includes.any(
          (include) =>
              include.from != null &&
              _couldTarget(snapshot, include.from!, fromTopic: topic),
        );
  }

  bool _topicSourcesCouldContainTarget(
    _RemovalSnapshot snapshot,
    Map<String, String> plannedSources,
  ) {
    for (final topic in snapshot.module.topics) {
      if (p.equals(topic.filePath, snapshot.topic.filePath)) {
        continue;
      }
      final path = normalizePath(topic.filePath);
      final source = plannedSources[path] ?? snapshot.sources[path]!;
      if (_topicSourceStillReferencesTarget(snapshot, topic, source)) {
        return true;
      }
    }
    return false;
  }

  int _removeAllTargetEntries(_RemovalSnapshot snapshot, XmlElement parent) {
    var promoted = 0;
    for (final child in parent.childElements.where(_isTocElement).toList()) {
      promoted += _removeAllTargetEntries(snapshot, child);
      if (!_elementTargets(snapshot, child, snapshot.topic.filePath)) {
        continue;
      }
      promoted += _removeAndPromote(child);
    }
    return promoted;
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

  bool _treeDocumentsCouldContainTarget(
    _RemovalSnapshot snapshot,
    Iterable<XmlDocument> documents,
  ) => documents.any((document) {
    final startPage = document.rootElement.getAttribute('start-page');
    if (startPage != null && _couldTarget(snapshot, startPage)) {
      return true;
    }
    return document.findAllElements('toc-element').any((element) {
      final reference = element.getAttribute('topic');
      return reference != null && _couldTarget(snapshot, reference);
    });
  });

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
    required this.module,
    required this.topic,
    required this.sources,
    required this.trees,
    required this.redirectRules,
    required this.fingerprint,
  });

  final CanonicalPathAnchor anchor;
  final WritersideModule module;
  final WritersideTopic topic;
  final Map<String, String> sources;
  final Map<String, _TreeSnapshot> trees;
  final Map<String, Set<String>> redirectRules;
  final String fingerprint;
}

class _TreeSnapshot {
  const _TreeSnapshot({
    required this.path,
    required this.source,
    required this.document,
  });

  final String path;
  final String source;
  final XmlDocument document;
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

String _referenceWithoutAnchor(String destination) =>
    destination.split('#').first.split('?').first;

String _oldWebFileName(
  WritersideTopic topic, {
  required bool disablePreprocessing,
}) {
  final explicit = topic.webFileName?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  final rawBase = p.basenameWithoutExtension(topic.fileName).trim();
  final base = disablePreprocessing
      ? _replaceUnsafeWebFileNameCharacters(rawBase)
      : rawBase
            .toLowerCase()
            .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
  return '$base.html';
}

String _replaceUnsafeWebFileNameCharacters(String value) => value
    .replaceAll(RegExp(r'[^\p{L}\p{N}._~-]+', unicode: true), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

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

String _unquoteDestination(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

String _decodeWritersideVariableEscapes(String value) =>
    value.replaceAll(RegExp('%25', caseSensitive: false), '%');

bool _sameWritersideReference(String first, String second) =>
    _decodeWritersideVariableEscapes(first) ==
    _decodeWritersideVariableEscapes(second);

String? _attributeValue(String element, String attribute) {
  final match = RegExp(
    '$attribute\\s*=\\s*(["\\\'])(.*?)\\1',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(element);
  return match?.group(2);
}

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
final RegExp _includePattern = RegExp(
  r'<include\b[^>]*(?:/>|>.*?</include\s*>)',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _writersideVariableReference = RegExp(
  r'(?<!\\)%([A-Za-z_][A-Za-z0-9_.-]*)%',
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
