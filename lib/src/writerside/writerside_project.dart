import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import 'writerside_document.dart';
import 'writerside_model.dart';
import 'writerside_module_service.dart';
import 'writerside_schema.dart';

enum WritersideSymbolKind {
  module,
  topic,
  element,
  snippet,
  variable,
  image,
  resource,
  instance,
  instanceGroup,
  category,
  seealso,
  redirect,
  apiSpecification,
  apiReference,
}

class WritersideSymbol {
  const WritersideSymbol({
    required this.name,
    required this.qualifiedName,
    required this.kind,
    required this.moduleId,
    required this.filePath,
    this.span,
  });

  final String name;
  final String qualifiedName;
  final WritersideSymbolKind kind;
  final String moduleId;
  final String filePath;
  final SourceSpan? span;
}

class WritersideReference {
  const WritersideReference({
    required this.value,
    required this.kind,
    required this.moduleId,
    required this.filePath,
    required this.span,
    this.origin,
    this.sourceValue,
  });

  final String value;
  final WritersideSymbolKind kind;
  final String moduleId;
  final String filePath;
  final SourceSpan span;
  final String? origin;
  final String? sourceValue;
}

class WritersideRenameEdit {
  const WritersideRenameEdit({
    required this.filePath,
    required this.span,
    required this.replacement,
  });

  final String filePath;
  final SourceSpan span;
  final String replacement;
}

class WritersideProjectIndex {
  const WritersideProjectIndex({
    required this.symbols,
    required this.references,
    required this.diagnostics,
  });

  final List<WritersideSymbol> symbols;
  final List<WritersideReference> references;
  final List<Diagnostic> diagnostics;

  factory WritersideProjectIndex.build(
    List<WritersideModule> modules, {
    Iterable<WritersideSymbol> fileSymbols = const [],
  }) {
    final symbols = <WritersideSymbol>[];
    final references = <WritersideReference>[];
    final diagnostics = <Diagnostic>[];
    final moduleIds = <WritersideModule, String>{
      for (final module in modules) module: _moduleId(module),
    };

    for (final module in modules) {
      final moduleId = moduleIds[module]!;
      symbols.add(
        WritersideSymbol(
          name: moduleId,
          qualifiedName: moduleId,
          kind: WritersideSymbolKind.module,
          moduleId: moduleId,
          filePath: module.config.filePath,
        ),
      );
      for (final topic in module.topics) {
        symbols.add(
          WritersideSymbol(
            name: topic.id,
            qualifiedName: '$moduleId:${topic.id}',
            kind: WritersideSymbolKind.topic,
            moduleId: moduleId,
            filePath: topic.filePath,
            span:
                topic.document.rootElement?.attributeSpans['id'] ??
                topic.document.rootElement?.span,
          ),
        );
        if (topic.fileName != topic.id) {
          symbols.add(
            WritersideSymbol(
              name: topic.fileName,
              qualifiedName: '$moduleId:${topic.fileName}',
              kind: WritersideSymbolKind.topic,
              moduleId: moduleId,
              filePath: topic.filePath,
              span: topic.document.rootElement?.span,
            ),
          );
        }
        final indexedElementIds = <String>{};
        for (final element in topic.document.elements) {
          final id = element.attributes['id']?.trim();
          if (id != null && id.isNotEmpty) {
            indexedElementIds.add(id);
            symbols.add(
              WritersideSymbol(
                name: id,
                qualifiedName: '$moduleId:${topic.id}#$id',
                kind: element.semanticKind == WritersideSemanticKind.snippet
                    ? WritersideSymbolKind.snippet
                    : element.name == 'seealso'
                    ? WritersideSymbolKind.seealso
                    : WritersideSymbolKind.element,
                moduleId: moduleId,
                filePath: topic.filePath,
                span: element.attributeSpans['id'] ?? element.span,
              ),
            );
          }
          _collectElementReferences(
            references,
            element,
            moduleId: moduleId,
            filePath: topic.filePath,
          );
          final capability = WritersideSchema.capabilityFor(element.name);
          for (final requiredAttribute
              in capability?.requiredAttributes ?? const <String>{}) {
            if ((element.attributes[requiredAttribute] ?? '').trim().isEmpty) {
              diagnostics.add(
                Diagnostic(
                  code: 'writerside.schema.missing-required-attribute',
                  severity: DiagnosticSeverity.warning,
                  filePath: topic.filePath,
                  args: {
                    'element': element.name,
                    'attribute': requiredAttribute,
                    'builderVersion': WritersideSchema.builderVersion,
                  },
                  sourceSpan: element.span,
                ),
              );
            }
          }
        }
        for (final elementId in topic.elementIds.where(
          (candidate) => !indexedElementIds.contains(candidate.id),
        )) {
          symbols.add(
            WritersideSymbol(
              name: elementId.id,
              qualifiedName: '$moduleId:${topic.id}#${elementId.id}',
              kind: WritersideSymbolKind.element,
              moduleId: moduleId,
              filePath: topic.filePath,
              span: elementId.span,
            ),
          );
        }
        for (final link in topic.links) {
          references.add(
            WritersideReference(
              value: link.destination,
              kind: WritersideSymbolKind.topic,
              moduleId: moduleId,
              filePath: topic.filePath,
              span: link.span,
              sourceValue: link.destination,
            ),
          );
        }
        for (final image in topic.images) {
          references.add(
            WritersideReference(
              value: image.destination,
              kind: WritersideSymbolKind.image,
              moduleId: moduleId,
              filePath: topic.filePath,
              span: image.span,
              sourceValue: image.destination,
            ),
          );
        }
        for (final variable in topic.variables.where(
          (candidate) => !candidate.escaped,
        )) {
          references.add(
            WritersideReference(
              value: variable.name,
              kind: WritersideSymbolKind.variable,
              moduleId: moduleId,
              filePath: topic.filePath,
              span: variable.span,
              sourceValue: '%${variable.name}%',
            ),
          );
        }
      }
      for (final variable in module.variables) {
        symbols.add(
          WritersideSymbol(
            name: variable.name,
            qualifiedName: '$moduleId:%${variable.name}%',
            kind: WritersideSymbolKind.variable,
            moduleId: moduleId,
            filePath: variable.span.filePath,
            span: variable.span,
          ),
        );
      }
      for (final instance in module.instances) {
        symbols.add(
          WritersideSymbol(
            name: instance.id,
            qualifiedName: '$moduleId:${instance.id}',
            kind: WritersideSymbolKind.instance,
            moduleId: moduleId,
            filePath: instance.sourceTreePath,
          ),
        );
        for (final node in instance.navigationTocRoots.expand(
          (root) => root.flatten(),
        )) {
          final topicReference = node.topicReference;
          if (topicReference != null) {
            references.add(
              WritersideReference(
                value: topicReference,
                kind: WritersideSymbolKind.topic,
                moduleId: moduleId,
                filePath: node.span.filePath,
                span: node.span,
                origin: node.origin,
                sourceValue: topicReference,
              ),
            );
          }
          final redirectTarget = node.targetForAcceptWebFileNames;
          if (redirectTarget != null) {
            final redirectName =
                node.acceptsWebFileNames ??
                node.acceptsWebFileNamesRef ??
                redirectTarget;
            symbols.add(
              WritersideSymbol(
                name: redirectName,
                qualifiedName: '$moduleId:redirect:$redirectName',
                kind: WritersideSymbolKind.redirect,
                moduleId: moduleId,
                filePath: node.span.filePath,
                span: node.span,
              ),
            );
            references.add(
              WritersideReference(
                value: redirectTarget,
                kind: WritersideSymbolKind.topic,
                moduleId: moduleId,
                filePath: node.span.filePath,
                span: node.span,
                origin: node.origin,
                sourceValue: redirectTarget,
              ),
            );
          }
        }
      }
      for (final group
          in module.instanceGroups?.groups.values ??
              const <WritersideInstanceGroup>[]) {
        symbols.add(
          WritersideSymbol(
            name: group.id,
            qualifiedName: '$moduleId:@${group.id}',
            kind: WritersideSymbolKind.instanceGroup,
            moduleId: moduleId,
            filePath: group.span.filePath,
            span: group.span,
          ),
        );
      }
      for (final category in module.categories) {
        symbols.add(
          WritersideSymbol(
            name: category.id,
            qualifiedName: '$moduleId:${category.id}',
            kind: WritersideSymbolKind.category,
            moduleId: moduleId,
            filePath: category.span.filePath,
            span: category.span,
          ),
        );
      }
    }
    symbols.addAll(fileSymbols);

    final groupedDefinitions = <String, List<WritersideSymbol>>{};
    for (final symbol in symbols.where(
      (symbol) =>
          symbol.kind == WritersideSymbolKind.topic ||
          symbol.kind == WritersideSymbolKind.element ||
          symbol.kind == WritersideSymbolKind.snippet ||
          symbol.kind == WritersideSymbolKind.variable,
    )) {
      groupedDefinitions
          .putIfAbsent(
            '${symbol.moduleId}:${symbol.kind.name}:'
            '${symbol.kind == WritersideSymbolKind.element || symbol.kind == WritersideSymbolKind.snippet ? symbol.filePath : ''}:'
            '${symbol.name}',
            () => [],
          )
          .add(symbol);
    }
    for (final duplicates in groupedDefinitions.values.where(
      (items) => items.length > 1,
    )) {
      for (final duplicate in duplicates.skip(1)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.index.duplicate-symbol',
            severity: DiagnosticSeverity.error,
            filePath: duplicate.filePath,
            args: {
              'name': duplicate.name,
              'kind': duplicate.kind.name,
              'module': duplicate.moduleId,
            },
            sourceSpan: duplicate.span,
            relatedSpans: [if (duplicates.first.span case final first?) first],
          ),
        );
      }
    }

    final modulesById = {
      for (final module in modules) moduleIds[module]!: module,
    };
    for (final reference in references.where(
      (reference) => reference.kind == WritersideSymbolKind.snippet,
    )) {
      final targetModule = modulesById[reference.origin ?? reference.moduleId];
      if (targetModule == null) {
        diagnostics.add(
          _referenceDiagnostic('writerside.index.unresolved-origin', reference),
        );
        continue;
      }
      final separator = reference.value.indexOf('#');
      final from = separator == -1
          ? reference.value
          : reference.value.substring(0, separator);
      final id = separator == -1
          ? null
          : reference.value.substring(separator + 1);
      final topics = from.isEmpty
          ? targetModule.topics
                .where((topic) => topic.filePath == reference.filePath)
                .toList()
          : targetModule.topicsMatchingReference(from);
      if (topics.length != 1) {
        diagnostics.add(
          _referenceDiagnostic(
            topics.isEmpty
                ? 'writerside.index.unresolved-reference'
                : 'writerside.index.ambiguous-reference',
            reference,
          ),
        );
        continue;
      }
      if (id != null &&
          id.isNotEmpty &&
          topics.single.document.elementById(id) == null) {
        diagnostics.add(
          _referenceDiagnostic(
            'writerside.index.unresolved-reference',
            reference,
          ),
        );
      }
    }

    return WritersideProjectIndex(
      symbols: List.unmodifiable(symbols),
      references: List.unmodifiable(references),
      diagnostics: sortDiagnostics(diagnostics),
    );
  }

  Iterable<WritersideSymbol> definitions(
    String reference, {
    String? moduleId,
    String? origin,
    WritersideSymbolKind? kind,
  }) {
    final targetModule = origin ?? moduleId;
    final normalized = reference.trim().split('#').last;
    return symbols.where((symbol) {
      final resourceMatch =
          symbol.kind == WritersideSymbolKind.image ||
          symbol.kind == WritersideSymbolKind.resource ||
          symbol.kind == WritersideSymbolKind.apiSpecification;
      return (targetModule == null || symbol.moduleId == targetModule) &&
          (kind == null || symbol.kind == kind) &&
          (symbol.name == normalized ||
              symbol.qualifiedName == reference ||
              (resourceMatch &&
                  p.basename(symbol.name) == p.basename(normalized)));
    });
  }

  Iterable<WritersideReference> findUsages(WritersideSymbol symbol) {
    return references.where((reference) {
      final normalized = reference.value.trim().split('#').last;
      final compatibleKind = switch (symbol.kind) {
        WritersideSymbolKind.element =>
          reference.kind == WritersideSymbolKind.snippet ||
              reference.kind == WritersideSymbolKind.topic,
        WritersideSymbolKind.apiSpecification =>
          reference.kind == WritersideSymbolKind.apiReference,
        _ => reference.kind == symbol.kind,
      };
      return compatibleKind &&
          normalized == symbol.name &&
          (reference.origin == null
              ? reference.moduleId == symbol.moduleId
              : reference.origin == symbol.moduleId);
    });
  }

  List<WritersideRenameEdit> safeRenameEdits(
    WritersideSymbol symbol,
    String newName,
  ) {
    final normalized = newName.trim();
    if (normalized.isEmpty ||
        !RegExp(r'^[A-Za-z_][A-Za-z0-9_.-]*$').hasMatch(normalized) ||
        symbol.span == null ||
        symbol.span!.endOffset - symbol.span!.startOffset !=
            symbol.name.length) {
      return const [];
    }
    final usages = findUsages(symbol).where((reference) {
      return reference.value == symbol.name ||
          reference.value.endsWith('#${symbol.name}');
    });
    return [
      WritersideRenameEdit(
        filePath: symbol.filePath,
        span: symbol.span!,
        replacement: normalized,
      ),
      for (final usage in usages)
        WritersideRenameEdit(
          filePath: usage.filePath,
          span: usage.span,
          replacement: _renamedReferenceValue(
            usage.sourceValue ?? usage.value,
            symbol.name,
            normalized,
          ),
        ),
    ];
  }

  Iterable<String> names(WritersideSymbolKind kind, {String? moduleId}) =>
      symbols
          .where(
            (symbol) =>
                symbol.kind == kind &&
                (moduleId == null || symbol.moduleId == moduleId),
          )
          .map((symbol) => symbol.name)
          .toSet();
}

class WritersideProject {
  const WritersideProject({
    required this.rootPath,
    required this.modules,
    required this.activeModuleId,
    required this.activeInstanceId,
    required this.index,
    required this.diagnostics,
  });

  final String rootPath;
  final List<WritersideModule> modules;
  final String? activeModuleId;
  final String? activeInstanceId;
  final WritersideProjectIndex index;
  final List<Diagnostic> diagnostics;

  WritersideModule? get activeModule {
    for (final module in modules) {
      if (_moduleId(module) == activeModuleId) {
        return module;
      }
    }
    return modules.firstOrNull;
  }

  WritersideInstance? get activeInstance {
    final module = activeModule;
    if (module == null) {
      return null;
    }
    for (final instance in module.instances) {
      if (instance.id == activeInstanceId) {
        return instance;
      }
    }
    return module.instances
        .where((instance) => !instance.isLibrary)
        .firstOrNull;
  }

  Map<String, WritersideModule> get modulesByOrigin => {
    for (final module in modules) _moduleId(module): module,
  };

  WritersideProject withSelection({
    required String moduleId,
    String? instanceId,
  }) {
    return WritersideProject(
      rootPath: rootPath,
      modules: modules,
      activeModuleId: moduleId,
      activeInstanceId: instanceId,
      index: index,
      diagnostics: diagnostics,
    );
  }
}

class WritersideProjectService {
  const WritersideProjectService({
    this.moduleService = const WritersideModuleService(),
    this.scanOptions = const WorkspaceScanOptions(),
  });

  final WritersideModuleService moduleService;
  final WorkspaceScanOptions scanOptions;

  Future<List<String>> discoverModuleRoots(String projectRoot) async {
    final root = normalizePath(projectRoot);
    final direct = [
      p.join(root, 'writerside.cfg'),
      p.join(root, 'project.ihp'),
    ].map(File.new).where((file) => file.existsSync());
    final roots = <String>{for (final file in direct) p.dirname(file.path)};
    final scan = await scanWorkspaceEntities(
      root,
      options: WorkspaceScanOptions(
        maxParsedFileBytes: scanOptions.maxParsedFileBytes,
        maxParsedDocuments: scanOptions.maxParsedDocuments,
        maxTreeEntries: scanOptions.maxTreeEntries,
        followLinks: false,
        includeUnsupportedFiles: true,
        includeDirectories: false,
        includeHiddenDirectories: false,
        includeExcludedDirectories: false,
      ),
    );
    for (final file in scan.entities.whereType<File>()) {
      if ({'writerside.cfg', 'project.ihp'}.contains(p.basename(file.path))) {
        roots.add(p.dirname(file.path));
      }
    }
    return roots.toList()..sort();
  }

  Future<WritersideProject> load(
    String projectRoot, {
    String? preferredModuleRoot,
  }) async {
    final roots = await discoverModuleRoots(projectRoot);
    final modules = <WritersideModule>[];
    for (final root in roots) {
      modules.add(await moduleService.load(root, options: scanOptions));
    }
    final index = WritersideProjectIndex.build(
      modules,
      fileSymbols: await _discoverFileSymbols(modules),
    );
    WritersideModule? active;
    if (preferredModuleRoot != null) {
      active = modules
          .where((module) => p.equals(module.rootPath, preferredModuleRoot))
          .firstOrNull;
    }
    active ??= modules.firstOrNull;
    final instance = active?.instances
        .where((candidate) => !candidate.isLibrary)
        .firstOrNull;
    return WritersideProject(
      rootPath: normalizePath(projectRoot),
      modules: List.unmodifiable(modules),
      activeModuleId: active == null ? null : _moduleId(active),
      activeInstanceId: instance?.id,
      index: index,
      diagnostics: sortDiagnostics([
        for (final module in modules) ...module.diagnostics,
        ...index.diagnostics,
      ]),
    );
  }

  Future<List<WritersideSymbol>> _discoverFileSymbols(
    List<WritersideModule> modules,
  ) async {
    final result = <WritersideSymbol>[];
    for (final module in modules) {
      final moduleId = _moduleId(module);
      for (final imageRoot in module.validatedImageDirs) {
        await _addDirectorySymbols(
          result,
          module: module,
          moduleId: moduleId,
          directoryPath: p.join(module.rootPath, imageRoot),
          kind: WritersideSymbolKind.image,
        );
      }
      await _addConfiguredDirectorySymbols(
        result,
        module: module,
        moduleId: moduleId,
        configuredPath: module.config.resourcesDir,
        kind: WritersideSymbolKind.resource,
      );
      await _addConfiguredDirectorySymbols(
        result,
        module: module,
        moduleId: moduleId,
        configuredPath: module.config.apiSpecificationsDir,
        kind: WritersideSymbolKind.apiSpecification,
      );
      final resourcesFile = module.config.resourcesFile;
      if (resourcesFile != null) {
        final absolute = normalizePath(p.join(module.rootPath, resourcesFile));
        if (_insideModule(module, absolute) && File(absolute).existsSync()) {
          result.add(
            WritersideSymbol(
              name: p.normalize(resourcesFile),
              qualifiedName: '$moduleId:${p.normalize(resourcesFile)}',
              kind: WritersideSymbolKind.resource,
              moduleId: moduleId,
              filePath: absolute,
            ),
          );
        }
      }
    }
    return result;
  }

  Future<void> _addConfiguredDirectorySymbols(
    List<WritersideSymbol> result, {
    required WritersideModule module,
    required String moduleId,
    required String? configuredPath,
    required WritersideSymbolKind kind,
  }) async {
    if (configuredPath == null || configuredPath.trim().isEmpty) {
      return;
    }
    final absolute = normalizePath(p.join(module.rootPath, configuredPath));
    if (!_insideModule(module, absolute)) {
      return;
    }
    await _addDirectorySymbols(
      result,
      module: module,
      moduleId: moduleId,
      directoryPath: absolute,
      kind: kind,
    );
  }

  Future<void> _addDirectorySymbols(
    List<WritersideSymbol> result, {
    required WritersideModule module,
    required String moduleId,
    required String directoryPath,
    required WritersideSymbolKind kind,
  }) async {
    final directory = normalizePath(directoryPath);
    if (!_insideModule(module, directory) ||
        !Directory(directory).existsSync()) {
      return;
    }
    final scan = await scanWorkspaceEntities(
      directory,
      options: WorkspaceScanOptions(
        maxParsedFileBytes: scanOptions.maxParsedFileBytes,
        maxParsedDocuments: scanOptions.maxParsedDocuments,
        maxTreeEntries: scanOptions.maxTreeEntries,
        followLinks: false,
        includeUnsupportedFiles: true,
        includeDirectories: false,
        includeHiddenDirectories: false,
        includeExcludedDirectories: false,
      ),
    );
    for (final file in scan.entities.whereType<File>()) {
      final relative = p.normalize(p.relative(file.path, from: directory));
      result.add(
        WritersideSymbol(
          name: relative,
          qualifiedName: '$moduleId:$relative',
          kind: kind,
          moduleId: moduleId,
          filePath: normalizePath(file.path),
        ),
      );
    }
  }
}

void _collectElementReferences(
  List<WritersideReference> references,
  WritersideElementNode element, {
  required String moduleId,
  required String filePath,
}) {
  final kind = element.semanticKind;
  if (kind == WritersideSemanticKind.include) {
    final from = element.attributes['from'];
    final id = element.attributes['element-id'];
    if (from != null || id != null) {
      references.add(
        WritersideReference(
          value: id == null ? from ?? '' : '${from ?? ''}#$id',
          kind: WritersideSymbolKind.snippet,
          moduleId: moduleId,
          filePath: filePath,
          span:
              element.attributeSpans[id == null ? 'from' : 'element-id'] ??
              element.span,
          origin: element.attributes['origin'],
          sourceValue: id ?? from,
        ),
      );
    }
  } else if (kind == WritersideSemanticKind.link) {
    final href = element.attributes['href'];
    if (href != null) {
      references.add(
        WritersideReference(
          value: href,
          kind: WritersideSymbolKind.topic,
          moduleId: moduleId,
          filePath: filePath,
          span: element.attributeSpans['href'] ?? element.span,
          origin: element.attributes['origin'],
          sourceValue: href,
        ),
      );
    }
  } else if (kind == WritersideSemanticKind.image) {
    final src = element.attributes['src'];
    if (src != null) {
      references.add(
        WritersideReference(
          value: src,
          kind: WritersideSymbolKind.image,
          moduleId: moduleId,
          filePath: filePath,
          span: element.attributeSpans['src'] ?? element.span,
          origin: element.attributes['origin'],
          sourceValue: src,
        ),
      );
    }
  } else if (kind == WritersideSemanticKind.resource) {
    final src = element.attributes['src'];
    if (src != null) {
      references.add(
        WritersideReference(
          value: src,
          kind: WritersideSymbolKind.resource,
          moduleId: moduleId,
          filePath: filePath,
          span: element.attributeSpans['src'] ?? element.span,
          origin: element.attributes['origin'],
          sourceValue: src,
        ),
      );
    }
  } else if (element.name == 'category') {
    final ref = element.attributes['ref'];
    if (ref != null) {
      references.add(
        WritersideReference(
          value: ref,
          kind: WritersideSymbolKind.category,
          moduleId: moduleId,
          filePath: filePath,
          span: element.attributeSpans['ref'] ?? element.span,
          sourceValue: ref,
        ),
      );
    }
  } else if ({
    'api-doc',
    'api-endpoint',
    'api-schema',
    'api-webhook',
  }.contains(element.name)) {
    final attribute = [
      'openapi-path',
      'src',
      'spec',
      'name',
      'endpoint',
    ].where(element.attributes.containsKey).firstOrNull;
    final value = attribute == null ? null : element.attributes[attribute];
    if (attribute != null && value != null) {
      references.add(
        WritersideReference(
          value: value,
          kind: WritersideSymbolKind.apiReference,
          moduleId: moduleId,
          filePath: filePath,
          span: element.attributeSpans[attribute] ?? element.span,
          origin: element.attributes['origin'],
          sourceValue: value,
        ),
      );
    }
  }
}

Diagnostic _referenceDiagnostic(String code, WritersideReference reference) =>
    Diagnostic(
      code: code,
      severity: DiagnosticSeverity.warning,
      filePath: reference.filePath,
      args: {'reference': reference.value},
      sourceSpan: reference.span,
    );

String _moduleId(WritersideModule module) =>
    module.config.moduleName?.trim().isNotEmpty == true
    ? module.config.moduleName!.trim()
    : p.basename(module.rootPath);

bool _insideModule(WritersideModule module, String candidate) {
  final root = normalizePath(module.rootPath);
  final normalized = normalizePath(candidate);
  return p.equals(root, normalized) || p.isWithin(root, normalized);
}

String _renamedReferenceValue(
  String sourceValue,
  String oldName,
  String newName,
) {
  if (sourceValue == oldName) {
    return newName;
  }
  if (sourceValue == '%$oldName%') {
    return '%$newName%';
  }
  if (sourceValue.endsWith('#$oldName')) {
    return '${sourceValue.substring(0, sourceValue.length - oldName.length)}'
        '$newName';
  }
  return newName;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
