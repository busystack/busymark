import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/source_span.dart';
import 'writerside_model.dart';

class WritersideTreeResolution {
  const WritersideTreeResolution({
    required this.instances,
    required this.diagnostics,
  });

  final List<WritersideInstance> instances;
  final List<Diagnostic> diagnostics;
}

/// Resolves the reusable and conditional TOC constructs documented for
/// Writerside instance tree files.
///
/// Only registered tree files from the already validated module model can be
/// resolved. This keeps include resolution inside the canonical module root
/// and prevents a tree attribute from becoming an unrestricted file read.
class WritersideTreeResolver {
  const WritersideTreeResolver();

  WritersideTreeResolution resolve({
    required String moduleRoot,
    required List<WritersideInstance> instances,
    WritersideInstanceGroupsConfig? instanceGroups,
  }) {
    final diagnostics = <Diagnostic>[];
    final reported = <String>{};
    final treesByPath = <String, WritersideInstance>{
      for (final instance in instances)
        p.normalize(instance.sourceTreePath): instance,
    };
    final groups = instanceGroups?.groups ?? const {};
    late final _ResolutionContext context;
    context = _ResolutionContext(
      moduleRoot: p.normalize(moduleRoot),
      treesByPath: treesByPath,
      groups: groups,
      diagnostics: diagnostics,
      reportedDiagnostics: reported,
    );

    final resolved = <WritersideInstance>[];
    for (final instance in instances) {
      final roots = _resolveRoot(instance, context);
      resolved.add(instance.withResolvedTocRoots(List.unmodifiable(roots)));
    }
    return WritersideTreeResolution(
      instances: List.unmodifiable(resolved),
      diagnostics: List.unmodifiable(diagnostics),
    );
  }

  List<TocNode> _resolveRoot(
    WritersideInstance destination,
    _ResolutionContext context,
  ) {
    final roots = _expandEntries(
      entries: destination.treeEntries.isEmpty
          ? destination.tocRoots
          : destination.treeEntries,
      destination: destination,
      ownerTree: destination,
      context: context,
      included: false,
      activeFilters: null,
      includeStack: <String>{},
      exposeSnippets: destination.isLibrary,
    );
    return roots;
  }

  List<TocNode> _expandEntries({
    required List<WritersideTreeEntry> entries,
    required WritersideInstance destination,
    required WritersideInstance ownerTree,
    required _ResolutionContext context,
    required bool included,
    required Set<String>? activeFilters,
    required Set<String> includeStack,
    required bool exposeSnippets,
  }) {
    final result = <TocNode>[];
    for (final entry in entries) {
      if (!_matchesEntry(
        entry,
        destination: destination,
        activeFilters: activeFilters,
        context: context,
      )) {
        continue;
      }
      switch (entry) {
        case TocNode():
          final children = _expandEntries(
            entries: entry.childEntries,
            destination: destination,
            ownerTree: ownerTree,
            context: context,
            included: included,
            activeFilters: activeFilters,
            includeStack: includeStack,
            exposeSnippets: false,
          );
          result.add(
            _copyNode(
              entry,
              children: children,
              included: included,
              sourceTreePath: ownerTree.sourceTreePath,
            ),
          );
        case WritersideTocInclude():
          result.addAll(
            _expandInclude(
              include: entry,
              destination: destination,
              ownerTree: ownerTree,
              context: context,
              activeFilters: activeFilters,
              includeStack: includeStack,
            ),
          );
        case WritersideTocSnippet():
          if (!exposeSnippets) {
            continue;
          }
          final children = _expandEntries(
            entries: entry.entries,
            destination: destination,
            ownerTree: ownerTree,
            context: context,
            included: false,
            activeFilters: activeFilters,
            includeStack: includeStack,
            exposeSnippets: true,
          );
          result.add(
            TocNode(
              tocTitle: entry.id,
              id: entry.id,
              instanceCondition: entry.instanceCondition,
              customFilter: entry.customFilter,
              origin: entry.origin,
              hidden: false,
              children: children,
              entries: entry.entries,
              sourceTreePath: ownerTree.sourceTreePath,
              sourceTocPath: null,
              span: entry.span,
            ),
          );
      }
    }
    return result;
  }

  List<TocNode> _expandInclude({
    required WritersideTocInclude include,
    required WritersideInstance destination,
    required WritersideInstance ownerTree,
    required _ResolutionContext context,
    required Set<String>? activeFilters,
    required Set<String> includeStack,
  }) {
    final from = include.from;
    final elementId = include.elementId;
    if (from == null || elementId == null) {
      return [_unresolvedInclude(include, 'invalid')];
    }
    if (include.origin != null) {
      _report(
        context,
        code: 'writerside.tree.external-include',
        severity: DiagnosticSeverity.info,
        filePath: include.span.filePath,
        span: include.span,
        args: {'origin': include.origin!, 'source': from, 'id': elementId},
      );
      return [_unresolvedInclude(include, 'external')];
    }

    final sourcePath = p.normalize(
      p.isAbsolute(from)
          ? from
          : p.join(p.dirname(ownerTree.sourceTreePath), from),
    );
    if (!p.equals(sourcePath, context.moduleRoot) &&
        !p.isWithin(context.moduleRoot, sourcePath)) {
      _report(
        context,
        code: 'writerside.tree.unsafe-include-source',
        severity: DiagnosticSeverity.error,
        filePath: include.span.filePath,
        span: include.span,
        args: {'source': from},
      );
      return [_unresolvedInclude(include, 'unsafe')];
    }
    final sourceTree = context.treesByPath[sourcePath];
    if (sourceTree == null) {
      _report(
        context,
        code: 'writerside.tree.unresolved-include-source',
        severity: DiagnosticSeverity.error,
        filePath: include.span.filePath,
        span: include.span,
        args: {'source': from},
      );
      return [_unresolvedInclude(include, 'source')];
    }
    final target = _findTarget(sourceTree.treeEntries, elementId);
    if (target == null) {
      _report(
        context,
        code: 'writerside.tree.unresolved-include-element',
        severity: DiagnosticSeverity.error,
        filePath: include.span.filePath,
        span: include.span,
        args: {'source': from, 'id': elementId},
      );
      return [_unresolvedInclude(include, 'element')];
    }
    final includeKey = '$sourcePath#$elementId';
    if (includeStack.contains(includeKey)) {
      _report(
        context,
        code: 'writerside.tree.circular-include',
        severity: DiagnosticSeverity.error,
        filePath: include.span.filePath,
        span: include.span,
        args: {'source': from, 'id': elementId},
      );
      return [_unresolvedInclude(include, 'circular')];
    }
    final filters = include.useFilters.isEmpty
        ? activeFilters
        : include.useFilters.toSet();
    final nextStack = {...includeStack, includeKey};
    return switch (target) {
      TocNode() => _expandEntries(
        entries: [target],
        destination: destination,
        ownerTree: sourceTree,
        context: context,
        included: true,
        activeFilters: filters,
        includeStack: nextStack,
        exposeSnippets: false,
      ),
      WritersideTocSnippet() =>
        _matchesEntry(
              target,
              destination: destination,
              // A snippet is a non-rendered container. An unfiltered wrapper
              // must still be entered so its filtered descendants can be
              // selected when `empty` was not requested.
              activeFilters: target.customFilter == null ? null : filters,
              context: context,
            )
            ? _expandEntries(
                entries: target.entries,
                destination: destination,
                ownerTree: sourceTree,
                context: context,
                included: true,
                activeFilters: filters,
                includeStack: nextStack,
                exposeSnippets: false,
              )
            : const [],
      WritersideTocInclude() => const [],
    };
  }

  WritersideTreeEntry? _findTarget(
    List<WritersideTreeEntry> entries,
    String id,
  ) {
    for (final entry in entries) {
      if (switch (entry) {
        TocNode() => entry.id == id,
        WritersideTocSnippet() => entry.id == id,
        WritersideTocInclude() => false,
      }) {
        return entry;
      }
      final nested = switch (entry) {
        TocNode() => _findTarget(entry.childEntries, id),
        WritersideTocSnippet() => _findTarget(entry.entries, id),
        WritersideTocInclude() => null,
      };
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  bool _matchesEntry(
    WritersideTreeEntry entry, {
    required WritersideInstance destination,
    required Set<String>? activeFilters,
    required _ResolutionContext context,
  }) {
    if (!_matchesInstance(
      entry.instanceCondition,
      destination.id,
      entry.span,
      context,
    )) {
      return false;
    }
    if (activeFilters == null) {
      return true;
    }
    final filter = entry.customFilter;
    if (filter == null || filter.trim().isEmpty) {
      return activeFilters.contains('empty');
    }
    final filters = filter
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    return filters.any(activeFilters.contains);
  }

  bool _matchesInstance(
    String? condition,
    String instanceId,
    SourceSpan span,
    _ResolutionContext context,
  ) {
    if (condition == null || condition.trim().isEmpty) {
      return true;
    }
    final trimmed = condition.trim();
    final negated = trimmed.startsWith('!');
    final body = negated ? trimmed.substring(1) : trimmed;
    var matches = false;
    for (final token
        in body
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)) {
      if (!token.startsWith('@')) {
        matches = matches || token == instanceId;
        continue;
      }
      final groupId = token.substring(1);
      final group = context.groups[groupId];
      if (group == null) {
        _report(
          context,
          code: 'writerside.tree.unknown-instance-group',
          severity: DiagnosticSeverity.warning,
          filePath: span.filePath,
          span: span,
          args: {'group': groupId},
        );
      } else {
        matches = matches || group.instanceIds.contains(instanceId);
      }
    }
    return negated ? !matches : matches;
  }

  TocNode _copyNode(
    TocNode node, {
    required List<TocNode> children,
    required bool included,
    required String sourceTreePath,
  }) {
    return TocNode(
      topicFileName: node.topicFileName,
      referenceTopicFileName: node.referenceTopicFileName,
      referenceInstanceId: node.referenceInstanceId,
      href: node.href,
      tocTitle: node.tocTitle,
      id: node.id,
      acceptsWebFileNames: node.acceptsWebFileNames,
      acceptsWebFileNamesRef: node.acceptsWebFileNamesRef,
      targetForAcceptWebFileNames: node.targetForAcceptWebFileNames,
      instanceCondition: node.instanceCondition,
      customFilter: node.customFilter,
      origin: node.origin,
      hidden: node.hidden,
      workInProgress: node.workInProgress,
      children: List.unmodifiable(children),
      entries: node.entries,
      sourceTreePath: sourceTreePath,
      sourceTocPath: node.sourceTocPath,
      included: included,
      span: node.span,
    );
  }

  TocNode _unresolvedInclude(WritersideTocInclude include, String reason) {
    return TocNode(
      hidden: false,
      children: const [],
      span: include.span,
      included: true,
      includeFrom: include.from,
      includeElementId: include.elementId,
      includeResolutionError: reason,
    );
  }

  void _report(
    _ResolutionContext context, {
    required String code,
    required DiagnosticSeverity severity,
    required String filePath,
    required SourceSpan span,
    required Map<String, String> args,
  }) {
    final key =
        '$code:${span.filePath}:${span.startOffset}:${args.values.join(':')}';
    if (!context.reportedDiagnostics.add(key)) {
      return;
    }
    context.diagnostics.add(
      Diagnostic(
        code: code,
        severity: severity,
        filePath: filePath,
        sourceSpan: span,
        args: args,
      ),
    );
  }
}

class _ResolutionContext {
  const _ResolutionContext({
    required this.moduleRoot,
    required this.treesByPath,
    required this.groups,
    required this.diagnostics,
    required this.reportedDiagnostics,
  });

  final String moduleRoot;
  final Map<String, WritersideInstance> treesByPath;
  final Map<String, WritersideInstanceGroup> groups;
  final List<Diagnostic> diagnostics;
  final Set<String> reportedDiagnostics;
}
