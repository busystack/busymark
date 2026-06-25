import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/local_image_resolver.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import 'writerside_model.dart';
import 'writerside_parsers.dart';

class WritersideModuleService {
  const WritersideModuleService({
    this.configParser = const WritersideConfigParser(),
    this.treeParser = const WritersideTreeParser(),
    this.topicParser = const WritersideTopicParser(),
    this.variablesParser = const WritersideVariablesParser(),
    this.categoriesParser = const WritersideCategoriesParser(),
    this.scanOptions = const WorkspaceScanOptions(),
  });

  final WritersideConfigParser configParser;
  final WritersideTreeParser treeParser;
  final WritersideTopicParser topicParser;
  final WritersideVariablesParser variablesParser;
  final WritersideCategoriesParser categoriesParser;
  final WorkspaceScanOptions scanOptions;

  Future<WritersideModule> load(String rootPath) async {
    final root = normalizePath(rootPath);
    final diagnostics = <Diagnostic>[];
    final configPath = await _resolveConfigPath(root);
    if (configPath == null) {
      final expectedPath = p.join(root, 'writerside.cfg');
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing',
          severity: DiagnosticSeverity.error,
          message: 'Writerside mode requires writerside.cfg or project.ihp.',
          filePath: expectedPath,
        ),
      );
      final emptyConfig = WritersideConfig(
        filePath: expectedPath,
        version: null,
        moduleName: null,
        topicRoots: const [WritersideTopicRoot(dir: 'topics', explicit: false)],
        imageRoots: const [WritersideImageRoot(dir: 'images', explicit: false)],
        apiSpecificationsDir: 'specifications',
        apiSpecificationsExplicit: false,
        buildConfigDir: 'cfg',
        buildConfigExplicit: false,
        snippetsDir: null,
        resourcesFile: null,
        resourcesDir: null,
        varsFile: null,
        categoriesFile: null,
        instanceGroupsFile: null,
        instances: const [],
        settings: const WritersideSettingsConfig(),
        diagnostics: const [],
      );
      return WritersideModule(
        rootPath: root,
        config: emptyConfig,
        instances: const [],
        topics: const [],
        variables: const [],
        categories: const [],
        diagnostics: diagnostics,
      );
    }
    final configSource = await File(configPath).readAsString();
    final config = configParser.parse(configPath, configSource);
    diagnostics.addAll(config.diagnostics);
    final usableTopicRoots = await _existingTopicRoots(
      diagnostics,
      root,
      config,
    );
    await _validateImageRoots(diagnostics, root, config);
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      root,
      config.buildConfigDir,
      explicit: config.buildConfigExplicit,
      code: 'writerside.config.missing-build-config-directory',
      severity: DiagnosticSeverity.info,
      message: 'Configured build config directory is missing.',
    );
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      root,
      config.apiSpecificationsDir,
      explicit: config.apiSpecificationsExplicit,
      code: 'writerside.config.missing-api-specifications-directory',
      severity: DiagnosticSeverity.info,
      message: 'Configured API specifications directory is missing.',
    );
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      root,
      config.snippetsDir,
      explicit: config.snippetsDir != null,
      code: 'writerside.config.missing-snippets-directory',
      severity: DiagnosticSeverity.warning,
      message: 'Configured snippets directory is missing.',
    );
    await _validateOptionalConfiguredFile(
      diagnostics,
      root,
      config.varsFile,
      code: 'writerside.config.missing-vars-file',
      message: 'Configured variables file is missing.',
    );
    await _validateOptionalConfiguredFile(
      diagnostics,
      root,
      config.categoriesFile,
      code: 'writerside.config.missing-categories-file',
      message: 'Configured categories file is missing.',
    );
    await _validateOptionalConfiguredFile(
      diagnostics,
      root,
      config.instanceGroupsFile,
      code: 'writerside.config.missing-instance-groups-file',
      message: 'Configured instance groups file is missing.',
    );

    final instances = <WritersideInstance>[];
    for (final source in config.instanceSources) {
      final treePath = p.join(root, source);
      if (!await File(treePath).exists()) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.missing-instance-tree',
            severity: DiagnosticSeverity.error,
            message: 'Registered instance tree "$source" does not exist.',
            filePath: configPath,
            sourceSpan: _stringSpan(configPath, configSource, source),
          ),
        );
        continue;
      }
      final treeSource = await File(treePath).readAsString();
      final instance = treeParser.parse(treePath, treeSource);
      diagnostics.addAll(instance.diagnostics);
      instances.add(instance);
    }

    final topics = <WritersideTopic>[];
    for (final topicsRoot in usableTopicRoots) {
      final scan = await scanWorkspaceEntities(
        topicsRoot,
        options: scanOptions,
      );
      diagnostics.addAll(scan.diagnostics);
      for (final entity in scan.entities.whereType<File>()) {
        final extension = p.extension(entity.path).toLowerCase();
        try {
          if (extension == '.md' || extension == '.markdown') {
            final source = await entity.readAsString();
            final topic = topicParser.parseMarkdown(
              filePath: entity.path,
              source: source,
              topicsRoot: topicsRoot,
            );
            diagnostics.addAll(topic.diagnostics);
            topics.add(topic);
          } else if (extension == '.topic') {
            final source = await entity.readAsString();
            final topic = topicParser.parseXml(
              filePath: entity.path,
              source: source,
              topicsRoot: topicsRoot,
            );
            diagnostics.addAll(topic.diagnostics);
            topics.add(topic);
          }
        } on Object catch (error) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.topic.read-failed',
              severity: DiagnosticSeverity.warning,
              message: 'Could not read topic file: $error',
              filePath: entity.path,
            ),
          );
        }
      }
    }

    final variables = <WritersideVariable>[];
    if (config.varsFile != null) {
      final file = File(p.join(root, config.varsFile));
      if (await file.exists()) {
        final parsed = variablesParser.parse(
          file.path,
          await file.readAsString(),
        );
        variables.addAll(parsed.$1);
        diagnostics.addAll(parsed.$2);
      }
    }
    final categories = <WritersideCategory>[];
    if (config.categoriesFile != null) {
      final file = File(p.join(root, config.categoriesFile));
      if (await file.exists()) {
        final parsed = categoriesParser.parse(
          file.path,
          await file.readAsString(),
        );
        categories.addAll(parsed.$1);
        diagnostics.addAll(parsed.$2);
      }
    }

    final module = WritersideModule(
      rootPath: root,
      config: config,
      instances: instances,
      topics: topics,
      variables: variables,
      categories: categories,
      diagnostics: const [],
    );
    diagnostics.addAll(_resolve(module));
    return WritersideModule(
      rootPath: module.rootPath,
      config: module.config,
      instances: module.instances,
      topics: module.topics,
      variables: module.variables,
      categories: module.categories,
      diagnostics: sortDiagnostics(diagnostics),
    );
  }

  Future<String?> _resolveConfigPath(String root) async {
    final configPath = p.join(root, 'writerside.cfg');
    if (await File(configPath).exists()) {
      return configPath;
    }
    final legacyPath = p.join(root, 'project.ihp');
    if (await File(legacyPath).exists()) {
      return legacyPath;
    }
    return null;
  }

  Future<List<String>> _existingTopicRoots(
    List<Diagnostic> diagnostics,
    String root,
    WritersideConfig config,
  ) async {
    final existing = <String>[];
    for (final topicRoot in config.topicRoots) {
      final path = p.join(root, topicRoot.dir);
      if (await Directory(path).exists()) {
        existing.add(path);
        continue;
      }
      if (topicRoot.explicit) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.missing-directory',
            severity: DiagnosticSeverity.error,
            message:
                'Configured topics directory is missing. (${topicRoot.dir})',
            filePath: path,
          ),
        );
      }
    }
    if (existing.isEmpty &&
        config.topicRoots.any(
          (root) => !root.explicit && root.dir == 'topics',
        )) {
      final path = p.join(root, 'topics');
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing-directory',
          severity: DiagnosticSeverity.error,
          message: 'Default topics directory is missing. (topics)',
          filePath: path,
        ),
      );
    }
    return existing;
  }

  Future<void> _validateImageRoots(
    List<Diagnostic> diagnostics,
    String root,
    WritersideConfig config,
  ) async {
    for (final imageRoot in config.imageRoots) {
      final path = p.join(root, imageRoot.dir);
      if (await Directory(path).exists()) {
        continue;
      }
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing-directory',
          severity: imageRoot.explicit
              ? DiagnosticSeverity.warning
              : DiagnosticSeverity.info,
          message: 'Configured images directory is missing. (${imageRoot.dir})',
          filePath: path,
        ),
      );
    }
  }

  Future<void> _validateOptionalConfiguredDirectory(
    List<Diagnostic> diagnostics,
    String root,
    String? relativePath, {
    required bool explicit,
    required String code,
    required DiagnosticSeverity severity,
    required String message,
  }) async {
    if (!explicit || relativePath == null || relativePath.isEmpty) {
      return;
    }
    final path = p.join(root, relativePath);
    if (await Directory(path).exists()) {
      return;
    }
    diagnostics.add(
      Diagnostic(
        code: code,
        severity: severity,
        message: '$message ($relativePath)',
        filePath: path,
      ),
    );
  }

  Future<void> _validateOptionalConfiguredFile(
    List<Diagnostic> diagnostics,
    String root,
    String? relativePath, {
    required String code,
    required String message,
  }) async {
    if (relativePath == null || relativePath.isEmpty) {
      return;
    }
    final path = p.join(root, relativePath);
    if (await File(path).exists()) {
      return;
    }
    diagnostics.add(
      Diagnostic(
        code: code,
        severity: DiagnosticSeverity.warning,
        message: '$message ($relativePath)',
        filePath: path,
      ),
    );
  }

  List<Diagnostic> _resolve(WritersideModule module) {
    final diagnostics = <Diagnostic>[];
    final variableNames = module.variableNames;
    final categoryIds = module.categories.map((item) => item.id).toSet();
    final topicIds = <String, WritersideTopic>{};
    for (final topic in module.topics) {
      final previous = topicIds[topic.id];
      if (previous == null) {
        topicIds[topic.id] = topic;
        continue;
      }
      diagnostics.add(
        Diagnostic(
          code: 'writerside.topic.duplicate-id',
          severity: DiagnosticSeverity.error,
          message:
              'Topic ID "${topic.id}" is used by multiple topic files in this help module.',
          filePath: topic.filePath,
        ),
      );
    }
    for (final instance in module.instances) {
      if (instance.startPage != null) {
        final resolved = _resolveTopicReference(module, instance.startPage!);
        if (resolved.isMissing) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.tree.missing-start-page',
              severity: DiagnosticSeverity.error,
              message: 'Start page "${instance.startPage}" does not exist.',
              filePath: instance.sourceTreePath,
            ),
          );
        } else if (resolved.isAmbiguous) {
          diagnostics.add(
            _ambiguousTopicReferenceDiagnostic(
              reference: instance.startPage!,
              filePath: instance.sourceTreePath,
            ),
          );
        }
      }
      for (final node in instance.tocRoots.expand((node) => node.flatten())) {
        final topic = node.topicFileName;
        if (topic != null) {
          final resolved = _resolveTopicReference(module, topic);
          if (resolved.isMissing) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.tree.missing-topic',
                severity: DiagnosticSeverity.error,
                message: 'TOC references missing topic "$topic".',
                filePath: instance.sourceTreePath,
                sourceSpan: node.span,
              ),
            );
          } else if (resolved.isAmbiguous) {
            diagnostics.add(
              _ambiguousTopicReferenceDiagnostic(
                reference: topic,
                filePath: instance.sourceTreePath,
                sourceSpan: node.span,
              ),
            );
          }
        }
        final href = node.href;
        if (href != null && !_validExternalHref(href)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.tree.invalid-href',
              severity: DiagnosticSeverity.warning,
              message: 'External href "$href" is invalid.',
              filePath: instance.sourceTreePath,
              sourceSpan: node.span,
            ),
          );
        }
      }
    }
    for (final topic in module.topics) {
      if (topic.title == null || topic.title!.trim().isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.topic.missing-title',
            severity: DiagnosticSeverity.warning,
            message: 'Topic "${topic.fileName}" is missing a title.',
            filePath: topic.filePath,
          ),
        );
      }
      final duplicateIds = <String, SourceSpan>{};
      for (final id in topic.elementIds) {
        if (duplicateIds.containsKey(id.id)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.topic.duplicate-element-id',
              severity: DiagnosticSeverity.error,
              message: 'Element id "${id.id}" appears more than once.',
              filePath: topic.filePath,
              sourceSpan: id.span,
              relatedSpans: [duplicateIds[id.id]!],
            ),
          );
        }
        duplicateIds[id.id] = id.span;
      }
      for (final variable in topic.variables) {
        if (!variableNames.contains(variable.name)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.variable.unresolved',
              severity: DiagnosticSeverity.warning,
              message: 'Variable "%${variable.name}%" is not declared.',
              filePath: topic.filePath,
              sourceSpan: variable.span,
            ),
          );
        }
      }
      for (final link in topic.links) {
        final destination = link.destination;
        if (_isExternal(destination)) {
          continue;
        }
        final parts = destination.split('#');
        final targetReference = parts.first;
        final anchor = parts.length > 1 ? parts.sublist(1).join('#') : null;
        final resolved = targetReference.isEmpty
            ? _TopicResolution([topic])
            : _resolveTopicReference(module, targetReference, fromTopic: topic);
        final target = resolved.topic;
        if (target == null) {
          diagnostics.add(
            resolved.isAmbiguous
                ? _ambiguousTopicReferenceDiagnostic(
                    reference: targetReference,
                    filePath: topic.filePath,
                    sourceSpan: link.span,
                  )
                : Diagnostic(
                    code: 'markdown.link.unresolved-target',
                    severity: DiagnosticSeverity.error,
                    message: 'Topic link "$destination" does not resolve.',
                    filePath: topic.filePath,
                    sourceSpan: link.span,
                  ),
          );
        } else if (anchor != null && anchor.isNotEmpty) {
          final anchors = target.elementIds.map((item) => item.id).toSet();
          if (!anchors.contains(anchor)) {
            diagnostics.add(
              Diagnostic(
                code: 'markdown.link.unresolved-anchor',
                severity: DiagnosticSeverity.warning,
                message:
                    'Anchor "$anchor" does not exist in "${target.fileName}".',
                filePath: topic.filePath,
                sourceSpan: link.span,
              ),
            );
          }
        }
      }
      for (final image in topic.images) {
        if (image.alt.trim().isEmpty) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.image.missing-alt',
              severity: DiagnosticSeverity.warning,
              message: 'Image "${image.destination}" is missing alt text.',
              filePath: topic.filePath,
              sourceSpan: image.span,
            ),
          );
        }
        if (_isExternal(image.destination)) {
          continue;
        }
        if (!_localImageExistsInAnyRoot(module, topic, image.destination)) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.image.missing-file',
              severity: DiagnosticSeverity.error,
              message: 'Image "${image.destination}" does not exist.',
              filePath: topic.filePath,
              sourceSpan: image.span,
            ),
          );
        }
      }
      for (final include in topic.includes) {
        if (include.from == null || include.from!.isEmpty) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.include.unresolved-source',
              severity: DiagnosticSeverity.error,
              message: '<include> is missing from.',
              filePath: topic.filePath,
              sourceSpan: include.span,
            ),
          );
          continue;
        }
        final resolved = _resolveTopicReference(
          module,
          include.from!,
          fromTopic: topic,
        );
        final target = resolved.topic;
        if (target == null) {
          if (!include.nullable) {
            diagnostics.add(
              resolved.isAmbiguous
                  ? _ambiguousTopicReferenceDiagnostic(
                      reference: include.from!,
                      filePath: topic.filePath,
                      sourceSpan: include.span,
                    )
                  : Diagnostic(
                      code: 'writerside.include.unresolved-source',
                      severity: DiagnosticSeverity.error,
                      message:
                          'Include source "${include.from}" does not exist.',
                      filePath: topic.filePath,
                      sourceSpan: include.span,
                    ),
            );
          }
          continue;
        }
        if (include.elementId != null &&
            !target.elementIds.any((item) => item.id == include.elementId)) {
          if (!include.nullable) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.include.unresolved-element',
                severity: DiagnosticSeverity.error,
                message:
                    'Include element "${include.elementId}" does not exist in "${include.from}".',
                filePath: topic.filePath,
                sourceSpan: include.span,
              ),
            );
          }
        }
      }
      for (final categoryRef in RegExp(
        r'<category\b[^>]*ref="([^"]+)"',
      ).allMatches(topic.markdown?.source ?? '')) {
        final ref = categoryRef.group(1)!;
        if (!categoryIds.contains(ref)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.category.unresolved',
              severity: DiagnosticSeverity.warning,
              message: 'Seealso category "$ref" is not declared.',
              filePath: topic.filePath,
              sourceSpan: SourceSpan.fromOffsets(
                filePath: topic.filePath,
                source: topic.markdown!.source,
                startOffset: categoryRef.start,
                endOffset: categoryRef.end,
              ),
            ),
          );
        }
      }
    }
    return diagnostics;
  }

  bool _validExternalHref(String href) {
    return Uri.tryParse(href)?.hasScheme ?? false;
  }

  _TopicResolution _resolveTopicReference(
    WritersideModule module,
    String reference, {
    WritersideTopic? fromTopic,
  }) {
    return _TopicResolution(
      module.topicsMatchingReference(reference, fromTopic: fromTopic),
    );
  }

  Diagnostic _ambiguousTopicReferenceDiagnostic({
    required String reference,
    required String filePath,
    SourceSpan? sourceSpan,
  }) {
    return Diagnostic(
      code: 'writerside.topic.ambiguous-reference',
      severity: DiagnosticSeverity.error,
      message:
          'Topic reference "$reference" matches multiple configured topic files.',
      filePath: filePath,
      sourceSpan: sourceSpan,
    );
  }

  bool _localImageExistsInAnyRoot(
    WritersideModule module,
    WritersideTopic topic,
    String destination,
  ) {
    for (final imagesDir in module.config.imagesDirs) {
      if (localImageExists(
        activeFilePath: topic.filePath,
        destination: destination,
        writersideRoot: module.rootPath,
        imagesDir: imagesDir,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _isExternal(String destination) {
    return destination.startsWith('http://') ||
        destination.startsWith('https://') ||
        destination.startsWith('mailto:');
  }

  SourceSpan _stringSpan(String filePath, String source, String value) {
    final index = source.indexOf(value);
    return SourceSpan.fromOffsets(
      filePath: filePath,
      source: source,
      startOffset: index == -1 ? 0 : index,
      endOffset: index == -1 ? source.length : index + value.length,
    );
  }
}

class _TopicResolution {
  const _TopicResolution(this.matches);

  final List<WritersideTopic> matches;

  bool get isMissing => matches.isEmpty;
  bool get isAmbiguous => matches.length > 1;
  WritersideTopic? get topic => matches.length == 1 ? matches.single : null;
}
