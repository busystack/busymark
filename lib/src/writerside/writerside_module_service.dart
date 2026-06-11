import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
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
    final configPath = p.join(root, 'writerside.cfg');
    final legacyPath = p.join(root, 'project.ihp');
    if (!await File(configPath).exists()) {
      if (await File(legacyPath).exists()) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.legacy-project-ihp-unsupported',
            severity: DiagnosticSeverity.error,
            message:
                'This looks like an older Writerside project configuration file. BusyMark currently supports writerside.cfg only.',
            filePath: legacyPath,
          ),
        );
      } else {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.missing',
            severity: DiagnosticSeverity.error,
            message: 'Writerside mode requires writerside.cfg.',
            filePath: configPath,
          ),
        );
      }
      final emptyConfig = WritersideConfig(
        filePath: configPath,
        moduleName: null,
        topicsDir: 'topics',
        imagesDir: 'images',
        snippetsDir: null,
        resourcesDir: null,
        apiSpecificationsDir: 'specifications',
        buildConfigDir: 'cfg',
        varsFile: null,
        categoriesFile: null,
        instanceSources: const [],
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
    await _validateConfiguredDirectory(
      diagnostics,
      root,
      config.topicsDir,
      'writerside.config.missing-directory',
      DiagnosticSeverity.error,
      'Configured topics directory is missing.',
    );
    await _validateConfiguredDirectory(
      diagnostics,
      root,
      config.imagesDir,
      'writerside.config.missing-directory',
      DiagnosticSeverity.warning,
      'Configured images directory is missing.',
    );
    await _validateConfiguredDirectory(
      diagnostics,
      root,
      config.buildConfigDir,
      'writerside.config.missing-directory',
      DiagnosticSeverity.info,
      'Configured build config directory is missing.',
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
    final topicsRoot = p.join(root, config.topicsDir);
    if (await Directory(topicsRoot).exists()) {
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

  Future<void> _validateConfiguredDirectory(
    List<Diagnostic> diagnostics,
    String root,
    String relativePath,
    String code,
    DiagnosticSeverity severity,
    String message,
  ) async {
    final path = p.join(root, relativePath);
    if (!await Directory(path).exists()) {
      diagnostics.add(
        Diagnostic(
          code: code,
          severity: severity,
          message: '$message ($relativePath)',
          filePath: path,
        ),
      );
    }
  }

  List<Diagnostic> _resolve(WritersideModule module) {
    final diagnostics = <Diagnostic>[];
    final topicsByFile = module.topicsByFileName;
    final variableNames = module.variableNames;
    final categoryIds = module.categories.map((item) => item.id).toSet();
    for (final instance in module.instances) {
      if (instance.startPage != null &&
          !topicsByFile.containsKey(instance.startPage)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.tree.missing-start-page',
            severity: DiagnosticSeverity.error,
            message: 'Start page "${instance.startPage}" does not exist.',
            filePath: instance.sourceTreePath,
          ),
        );
      }
      for (final node in instance.tocRoots.expand((node) => node.flatten())) {
        final topic = node.topicFileName;
        if (topic != null && !topicsByFile.containsKey(topic)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.tree.missing-topic',
              severity: DiagnosticSeverity.error,
              message: 'TOC references missing topic "$topic".',
              filePath: instance.sourceTreePath,
              sourceSpan: node.span,
            ),
          );
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
        final targetName = parts.first.isEmpty
            ? topic.fileName
            : p.basename(parts.first);
        final anchor = parts.length > 1 ? parts.sublist(1).join('#') : null;
        final target = topicsByFile[targetName];
        if (target == null) {
          diagnostics.add(
            Diagnostic(
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
                message: 'Anchor "$anchor" does not exist in "$targetName".',
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
        final imagePath = p.join(
          module.rootPath,
          module.config.imagesDir,
          image.destination,
        );
        final relativePath = p.join(
          p.dirname(topic.filePath),
          image.destination,
        );
        if (!File(imagePath).existsSync() && !File(relativePath).existsSync()) {
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
        final target = topicsByFile[p.basename(include.from!)];
        if (target == null) {
          if (!include.nullable) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.include.unresolved-source',
                severity: DiagnosticSeverity.error,
                message: 'Include source "${include.from}" does not exist.',
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

class WritersideSummaryExporter {
  const WritersideSummaryExporter();

  String export(WritersideModule module) {
    final json = {
      'kind': 'writersideModule',
      'rootPath': module.rootPath,
      'moduleName': module.config.moduleName,
      'instances': [
        for (final instance in module.instances)
          {
            'id': instance.id,
            'name': instance.name,
            'startPage': instance.startPage,
            'topicCount': instance.topicFileSet.length,
          },
      ],
      'topics': [
        for (final topic in module.topics)
          {
            'id': topic.id,
            'file': topic.fileName,
            'title': topic.title,
            'format': topic.format.name,
          },
      ],
      'variables': [
        for (final variable in module.variables)
          {'name': variable.name, 'value': variable.value},
      ],
      'categories': [
        for (final category in module.categories)
          {'id': category.id, 'name': category.name, 'order': category.order},
      ],
      'diagnostics': module.diagnostics.map((item) => item.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}

class DiagnosticReportExporter {
  const DiagnosticReportExporter();

  String exportJson(Iterable<Diagnostic> diagnostics) {
    return const JsonEncoder.withIndent('  ').convert([
      for (final diagnostic in sortDiagnostics(diagnostics))
        diagnostic.toJson(),
    ]);
  }
}
