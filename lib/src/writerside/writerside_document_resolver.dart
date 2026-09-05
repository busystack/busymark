import '../core/diagnostic.dart';
import '../markdown/busymark_document.dart';
import 'writerside_document.dart';
import 'writerside_model.dart';
import 'writerside_schema.dart';
import 'writerside_source_loader.dart';
import 'writerside_code_selection.dart';

class WritersideResolveContext {
  const WritersideResolveContext({
    required this.module,
    required this.topic,
    this.instance,
    this.modulesByOrigin = const {},
  });

  final WritersideModule module;
  final WritersideTopic topic;
  final WritersideInstance? instance;
  final Map<String, WritersideModule> modulesByOrigin;
}

class ResolvedWritersideDocument {
  const ResolvedWritersideDocument({
    required this.document,
    required this.title,
    required this.diagnostics,
  });

  final WritersideDocument document;
  final String? title;
  final List<Diagnostic> diagnostics;
}

/// Resolves instance-sensitive Writerside semantics above the lossless tree.
/// Preview, navigation, outline, and export can therefore consume the same
/// concrete representation.
class WritersideDocumentResolver {
  const WritersideDocumentResolver();

  ResolvedWritersideDocument resolve(
    WritersideDocument document,
    WritersideResolveContext context,
  ) {
    final state = _ResolveState(context);
    final variables = <String, String>{
      for (final variable in context.module.variables)
        if (state._matchesInstance(variable.instanceCondition, context.module))
          variable.name: variable.value,
      if (context.instance case final instance?) ...{
        'instance': instance.name,
        'instance-lowercase': instance.name.toLowerCase(),
        'currentId': instance.id,
      },
      'thisTopic': context.topic.id,
    };
    final nodes = state.resolveNodes(
      document.nodes,
      module: context.module,
      topic: context.topic,
      variables: variables,
      activeFilters: null,
      includeStack: {'${context.topic.filePath}#'},
      inheritedIgnoreVariables: false,
    );
    final resolved = document.copyWith(nodes: List.unmodifiable(nodes));
    return ResolvedWritersideDocument(
      document: resolved,
      title: state.titleFor(resolved) ?? context.topic.title,
      diagnostics: sortDiagnostics(state.diagnostics),
    );
  }
}

class _ResolveState {
  _ResolveState(this.context);

  final WritersideResolveContext context;
  final List<Diagnostic> diagnostics = [];
  final Set<String> _unresolvedVariables = {};

  List<WritersideDocumentNode> resolveNodes(
    Iterable<WritersideDocumentNode> nodes, {
    required WritersideModule module,
    required WritersideTopic topic,
    required Map<String, String> variables,
    required Set<String>? activeFilters,
    required Set<String> includeStack,
    required bool inheritedIgnoreVariables,
    Map<String, String> arguments = const {},
  }) {
    final scopedVariables = {...variables};
    for (final node in nodes.whereType<WritersideElementNode>()) {
      if (node.semanticKind != WritersideSemanticKind.variable ||
          !_matchesConditions(node.attributes, activeFilters, module)) {
        continue;
      }
      final name = node.attributes['name']?.trim();
      final value = node.attributes['value'];
      if (name != null && name.isNotEmpty && value != null) {
        scopedVariables[name] = _interpolate(
          value,
          scopedVariables,
          node,
          ignore: inheritedIgnoreVariables,
        );
      }
    }
    scopedVariables.addAll(arguments);

    final result = <WritersideDocumentNode>[];
    final provenance = WritersideSourceProvenance(
      moduleRoot: module.rootPath,
      topicPath: topic.filePath,
    );
    for (final node in nodes) {
      if (node is WritersideTextNode) {
        result.add(
          node.copyWith(
            text: inheritedIgnoreVariables
                ? node.text
                : _interpolate(node.text, scopedVariables, node, ignore: false),
            provenance: provenance,
          ),
        );
        continue;
      }
      if (node is WritersideRawNode) {
        if (!writersideIgnorableRaw(node.rawSource)) {
          _referenceDiagnostic(
            code: 'writerside.content.unsupported',
            node: node,
          );
        }
        result.add(node.copyWith(provenance: provenance));
        continue;
      }
      if (node is WritersideMarkdownBlockNode) {
        if (!_matchesConditions(node.block.attributes, activeFilters, module)) {
          continue;
        }
        result.add(
          node.copyWith(
            block: _resolveMarkdownBlock(
              node.block,
              module: module,
              topic: topic,
              variables: scopedVariables,
              ignoreVariables: inheritedIgnoreVariables,
              sourceNode: node,
            ),
            provenance: provenance,
          ),
        );
        continue;
      }
      final element = node as WritersideElementNode;
      if (!_matchesConditions(element.attributes, activeFilters, module)) {
        continue;
      }
      if (element.semanticKind == null) {
        _referenceDiagnostic(
          code: 'writerside.content.unsupported',
          node: element,
          args: {'element': element.name},
          severity: DiagnosticSeverity.warning,
        );
      }
      if (element.semanticKind == WritersideSemanticKind.variable) {
        continue;
      }
      if (element.semanticKind == WritersideSemanticKind.include) {
        result.addAll(
          _resolveInclude(
            element,
            module: module,
            topic: topic,
            variables: scopedVariables,
            includeStack: includeStack,
            inheritedIgnoreVariables: inheritedIgnoreVariables,
          ),
        );
        continue;
      }

      final ignoreVariables = _ignoreVariablesFor(
        element,
        inheritedIgnoreVariables,
      );
      final attributes = <String, String>{
        for (final entry in element.attributes.entries)
          entry.key: _interpolate(
            entry.value,
            scopedVariables,
            element,
            ignore:
                ignoreVariables ||
                {'instance', 'filter', 'use-filter'}.contains(entry.key),
          ),
      };
      final children = resolveNodes(
        element.children,
        module: module,
        topic: topic,
        variables: scopedVariables,
        activeFilters: activeFilters,
        includeStack: includeStack,
        inheritedIgnoreVariables: ignoreVariables,
      );
      if (element.semanticKind == WritersideSemanticKind.codeBlock &&
          attributes.containsKey('src')) {
        attributes[writersideResolvedSourceAttribute] = _resolveCodeSource(
          attributes,
          module: module,
          topic: topic,
          node: element,
          variables: scopedVariables,
          ignore: ignoreVariables,
        );
      }
      if (element.semanticKind == WritersideSemanticKind.link) {
        attributes.addAll(
          _resolveLink(attributes, module: module, topic: topic, node: element),
        );
      }
      if (element.semanticKind == WritersideSemanticKind.condition) {
        result.addAll(children);
      } else {
        result.add(
          element.copyWith(
            attributes: Map.unmodifiable(attributes),
            children: List.unmodifiable(children),
            provenance: provenance,
          ),
        );
      }
    }
    return result;
  }

  String _resolveCodeSource(
    Map<String, String> attributes, {
    required WritersideModule module,
    required WritersideTopic topic,
    required WritersideDocumentNode node,
    required Map<String, String> variables,
    required bool ignore,
  }) {
    final reference = attributes['src']!;
    final loaded = module
        .sourceFiles[WritersideSourceLoader.key(topic.filePath, reference)];
    try {
      if (loaded?.text == null) {
        throw FormatException(loaded?.failure ?? 'missing');
      }
      return _interpolate(
        const WritersideCodeSelection().select(loaded!.text!, attributes),
        variables,
        node,
        ignore: ignore,
      );
    } on FormatException catch (error) {
      _referenceDiagnostic(
        code: 'writerside.source.invalid',
        node: node,
        args: {'reference': reference, 'reason': error.message},
      );
      return 'Unable to load $reference: ${error.message}';
    }
  }

  Map<String, String> _resolveLink(
    Map<String, String> attributes, {
    required WritersideModule module,
    required WritersideTopic topic,
    required WritersideDocumentNode node,
  }) {
    final href = attributes['href']?.trim() ?? '';
    final hash = href.indexOf('#');
    final path = hash < 0 ? href : href.substring(0, hash);
    final anchor =
        attributes['anchor']?.replaceFirst(RegExp(r'^#'), '') ??
        (hash < 0 ? '' : href.substring(hash + 1));
    final destination = '$path${anchor.isEmpty ? '' : '#$anchor'}';
    if (Uri.tryParse(path)?.hasScheme == true) {
      return {
        'resolved-destination': destination,
        'resolved-label': destination,
        'resolved-available': 'true',
      };
    }
    final origin = attributes['origin'];
    final targetModule = origin == null
        ? module
        : context.modulesByOrigin[origin];
    final targetTopic = path.isEmpty
        ? topic
        : targetModule?.topicByReference(
                path,
                fromTopic: identical(module, targetModule) ? topic : null,
              ) ??
              targetModule?.topicsById[path];
    final target = anchor.isEmpty
        ? null
        : targetTopic?.document.contentById(anchor)?.first;
    final instance = context.instance;
    var available =
        targetModule != null &&
        targetTopic != null &&
        (anchor.isEmpty || target != null);
    if (available &&
        instance != null &&
        targetTopic.filePath != context.topic.filePath) {
      available = instance.navigationTocRoots
          .expand((root) => root.flatten())
          .any((entry) {
            final entryModule = entry.origin == null
                ? context.module
                : context.modulesByOrigin[entry.origin];
            return entry.topicReference != null &&
                entryModule
                        ?.topicByReference(entry.topicReference!)
                        ?.filePath ==
                    targetTopic.filePath;
          });
    }
    if (target is WritersideElementNode) {
      available =
          available &&
          _matchesInstance(target.attributes['instance'], targetModule!);
    } else if (target is WritersideMarkdownBlockNode) {
      available =
          available &&
          _matchesInstance(target.block.attributes['instance'], targetModule!);
    }
    final targetTitle = target is WritersideElementNode
        ? target.attributes['title'] ??
              target.children
                  .whereType<WritersideElementNode>()
                  .where((element) => element.name == 'title')
                  .firstOrNull
                  ?.plainText ??
              target.plainText
        : target?.plainText;
    final label = targetTitle?.trim().isNotEmpty == true
        ? targetTitle!
        : targetTopic?.title ?? destination;
    final summary =
        attributes['summary'] ??
        targetTopic?.document.elements
            .where((element) => element.name == 'link-summary')
            .firstOrNull
            ?.plainText ??
        targetTopic?.document.elements
            .where((element) => element.name == 'p')
            .firstOrNull
            ?.plainText;
    if (!available && attributes['nullable'] != 'true') {
      _referenceDiagnostic(
        code: 'writerside.link.unavailable',
        node: node,
        args: {'destination': destination},
      );
    }
    return {
      'resolved-label': label,
      'resolved-destination': path.isEmpty
          ? '#$anchor'
          : '${targetTopic?.filePath ?? path}${anchor.isEmpty ? '' : '#$anchor'}',
      'resolved-available': '$available',
      if (summary != null) 'summary': summary.trim(),
    };
  }

  List<WritersideDocumentNode> _resolveInclude(
    WritersideElementNode include, {
    required WritersideModule module,
    required WritersideTopic topic,
    required Map<String, String> variables,
    required Set<String> includeStack,
    required bool inheritedIgnoreVariables,
  }) {
    final origin = include.attributes['origin']?.trim();
    final targetModule = origin == null || origin.isEmpty
        ? module
        : context.modulesByOrigin[origin];
    if (targetModule == null) {
      _referenceDiagnostic(
        code: 'writerside.include.unresolved-origin',
        node: include,
        args: {'origin': origin},
      );
      return const [];
    }

    final from = include.attributes['from']?.trim();
    WritersideTopic? targetTopic;
    if (from == null || from.isEmpty) {
      targetTopic = identical(targetModule, module) ? topic : null;
    } else {
      final matches = targetModule.topicsMatchingReference(
        from,
        fromTopic: identical(targetModule, module) ? topic : null,
      );
      if (matches.length > 1) {
        _referenceDiagnostic(
          code: 'writerside.include.ambiguous-source',
          node: include,
          args: {'from': from},
        );
        return const [];
      }
      targetTopic = matches.firstOrNull;
    }
    final nullable = include.attributes['nullable'] == 'true';
    if (targetTopic == null) {
      if (!nullable) {
        _referenceDiagnostic(
          code: 'writerside.include.unresolved-source',
          node: include,
          args: {'from': from},
        );
      }
      return const [];
    }

    final elementId = include.attributes['element-id']?.trim();
    final cycleKey = '${targetTopic.filePath}#${elementId ?? ''}';
    if (!includeStack.add(cycleKey)) {
      _referenceDiagnostic(
        code: 'writerside.include.cycle',
        node: include,
        args: {'from': from, 'elementId': elementId},
      );
      return const [];
    }
    try {
      Iterable<WritersideDocumentNode> selected;
      if (elementId != null && elementId.isNotEmpty) {
        final target = targetTopic.document.contentById(elementId);
        if (target == null) {
          if (!nullable) {
            _referenceDiagnostic(
              code: 'writerside.include.unresolved-element',
              node: include,
              args: {'from': from, 'elementId': elementId},
            );
          }
          return const [];
        }
        final first = target.first;
        selected =
            first is WritersideElementNode &&
                first.semanticKind == WritersideSemanticKind.snippet
            ? (_matchesConditions(first.attributes, null, targetModule)
                  ? first.children
                  : const [])
            : target;
      } else {
        final root = targetTopic.document.rootElement;
        selected = root == null
            ? targetTopic.document.nodes
            : root.children.where((node) {
                return node is! WritersideElementNode ||
                    (node.semanticKind != WritersideSemanticKind.title &&
                        node.semanticKind != WritersideSemanticKind.metadata &&
                        node.semanticKind != WritersideSemanticKind.snippet);
              });
      }

      final includeVariables = <String, String>{
        for (final variable in targetModule.variables)
          if (_matchesInstance(variable.instanceCondition, targetModule))
            variable.name: variable.value,
        ...variables,
      };
      final arguments = <String, String>{};
      for (final child in include.children.whereType<WritersideElementNode>()) {
        if (child.semanticKind != WritersideSemanticKind.variable ||
            !_matchesConditions(child.attributes, null, module)) {
          continue;
        }
        final name = child.attributes['name']?.trim();
        final value = child.attributes['value'];
        if (name != null && name.isNotEmpty && value != null) {
          arguments[name] = _interpolate(
            value,
            variables,
            child,
            ignore: false,
          );
        }
      }
      final filters = _tokens(include.attributes['use-filter']);
      final resolved = resolveNodes(
        selected,
        module: targetModule,
        topic: targetTopic,
        variables: includeVariables,
        arguments: arguments,
        activeFilters: filters.isEmpty ? null : filters,
        includeStack: includeStack,
        inheritedIgnoreVariables: inheritedIgnoreVariables,
      );
      if (resolved.isEmpty && !nullable) {
        _referenceDiagnostic(
          code: 'writerside.include.filtered-out',
          node: include,
          args: {'from': from, 'elementId': elementId},
          severity: DiagnosticSeverity.info,
        );
      }
      return resolved;
    } finally {
      includeStack.remove(cycleKey);
    }
  }

  bool _matchesConditions(
    Map<String, String> attributes,
    Set<String>? activeFilters,
    WritersideModule module,
  ) {
    if (!_matchesInstance(attributes['instance'], module)) {
      return false;
    }
    final filters = _tokens(attributes['filter']);
    if (activeFilters == null) {
      return true;
    }
    if (filters.isEmpty) {
      return activeFilters.contains('empty');
    }
    return filters.any(activeFilters.contains);
  }

  bool _matchesInstance(String? condition, WritersideModule module) {
    final normalized = condition?.trim() ?? '';
    final negated = normalized.startsWith('!');
    final tokens = _tokens(negated ? normalized.substring(1) : normalized);
    if (tokens.isEmpty) {
      return true;
    }
    final matches = tokens.any((token) => _instanceTokenMatches(token, module));
    if (negated) {
      return !matches;
    }
    return matches;
  }

  bool _instanceTokenMatches(String token, WritersideModule module) {
    final instance = context.instance;
    if (instance == null) {
      return false;
    }
    if (token.startsWith('@')) {
      return module.instanceGroups?.groups[token.substring(1)]?.instanceIds
              .contains(instance.id) ??
          false;
    }
    return token == instance.id;
  }

  bool _ignoreVariablesFor(WritersideElementNode element, bool inherited) {
    final explicit = element.attributes['ignore-vars'];
    if (explicit == 'true') {
      return true;
    }
    if (explicit == 'false') {
      return false;
    }
    if (inherited) {
      return true;
    }
    if (context.module.config.settings.smartIgnoreVars != true) {
      return false;
    }
    return {
      WritersideSemanticKind.codeBlock,
      WritersideSemanticKind.link,
      WritersideSemanticKind.image,
    }.contains(element.semanticKind);
  }

  BusyBlock _resolveMarkdownBlock(
    BusyBlock block, {
    required WritersideModule module,
    required WritersideTopic topic,
    required Map<String, String> variables,
    required bool ignoreVariables,
    required WritersideDocumentNode sourceNode,
  }) {
    final explicit = block.attributes['ignore-vars'];
    final smart =
        context.module.config.settings.smartIgnoreVars == true &&
        {BusyBlockKind.codeBlock, BusyBlockKind.image}.contains(block.kind);
    final ignore =
        explicit == 'true' ||
        (explicit != 'false' && (ignoreVariables || smart));
    BusyInline resolveInline(BusyInline inline) {
      final resolved = inline.copyWith(
        text: _interpolate(inline.text, variables, sourceNode, ignore: ignore),
        destination: inline.destination == null
            ? null
            : _interpolate(
                inline.destination!,
                variables,
                sourceNode,
                ignore: ignore,
              ),
        children: inline.children.map(resolveInline).toList(growable: false),
      );
      if (resolved.kind != BusyInlineKind.link) return resolved;
      final attributes = _resolveLink(
        {...resolved.attributes, 'href': resolved.destination ?? ''},
        module: module,
        topic: topic,
        node: sourceNode,
      );
      return resolved.copyWith(
        kind:
            resolved.attributes['nullable'] == 'true' &&
                attributes['resolved-available'] == 'false'
            ? BusyInlineKind.text
            : BusyInlineKind.link,
        text: resolved.plainText.trim().isEmpty
            ? attributes['resolved-label']
            : resolved.text,
        destination: attributes['resolved-destination'],
        attributes: {...resolved.attributes, ...attributes},
      );
    }

    final sourceText =
        block.kind == BusyBlockKind.codeBlock &&
            block.attributes.containsKey('src')
        ? _resolveCodeSource(
            block.attributes,
            module: module,
            topic: topic,
            node: sourceNode,
            variables: variables,
            ignore: ignore,
          )
        : null;
    return block.copyWith(
      inlines: sourceText == null
          ? block.inlines.map(resolveInline).toList(growable: false)
          : [BusyInline(kind: BusyInlineKind.text, text: sourceText)],
      children: [
        for (final child in block.children)
          _resolveMarkdownBlock(
            child,
            module: module,
            topic: topic,
            variables: variables,
            ignoreVariables: ignore,
            sourceNode: sourceNode,
          ),
      ],
      attributes: {
        if (sourceText != null) writersideResolvedSourceAttribute: sourceText,
        for (final entry in block.attributes.entries)
          entry.key: _interpolate(
            entry.value,
            variables,
            sourceNode,
            ignore: ignore,
          ),
      },
    );
  }

  String _interpolate(
    String value,
    Map<String, String> variables,
    WritersideDocumentNode node, {
    required bool ignore,
  }) {
    if (ignore || !value.contains('%')) {
      return value;
    }
    return value.replaceAllMapped(
      RegExp(r'%(\\)?([A-Za-z_][A-Za-z0-9_.-]*)%'),
      (match) {
        final name = match.group(2)!;
        if (match.group(1) != null) {
          return '%$name%';
        }
        final replacement = variables[name];
        if (replacement != null) {
          return replacement;
        }
        final key = '${node.span.filePath}:${node.span.startOffset}:$name';
        if (_unresolvedVariables.add(key)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.variable.unresolved',
              severity: DiagnosticSeverity.warning,
              filePath: node.span.filePath,
              args: {'name': name},
              sourceSpan: node.span,
            ),
          );
        }
        return match.group(0)!;
      },
    );
  }

  String? titleFor(WritersideDocument document) {
    final root = document.rootElement;
    if (root == null) {
      return context.topic.title;
    }
    final conditional = root.children
        .whereType<WritersideElementNode>()
        .where(
          (element) => element.semanticKind == WritersideSemanticKind.title,
        )
        .map((element) => element.plainText.trim())
        .where((title) => title.isNotEmpty)
        .firstOrNull;
    return conditional ?? root.attributes['title']?.trim();
  }

  void _referenceDiagnostic({
    required String code,
    required WritersideDocumentNode node,
    Map<String, Object?> args = const {},
    DiagnosticSeverity severity = DiagnosticSeverity.error,
  }) {
    diagnostics.add(
      Diagnostic(
        code: code,
        severity: severity,
        filePath: node.span.filePath,
        args: args,
        sourceSpan: node.span,
      ),
    );
  }
}

Set<String> _tokens(String? value) => {
  for (final token in value?.split(',') ?? const <String>[])
    if (token.trim().isNotEmpty) token.trim(),
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
