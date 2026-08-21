import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../core/diagnostic.dart';
import '../core/local_image_resolver.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../core/uri_utils.dart';
import 'writerside_model.dart';
import 'writerside_parsers.dart';
import 'writerside_tree_resolver.dart';

class WritersideModuleService {
  const WritersideModuleService({
    this.configParser = const WritersideConfigParser(),
    this.buildProfilesParser = const WritersideBuildProfilesParser(),
    this.instanceGroupsParser = const WritersideInstanceGroupsParser(),
    this.treeParser = const WritersideTreeParser(),
    this.treeResolver = const WritersideTreeResolver(),
    this.topicParser = const WritersideTopicParser(),
    this.variablesParser = const WritersideVariablesParser(),
    this.categoriesParser = const WritersideCategoriesParser(),
    this.scanOptions = const WorkspaceScanOptions(),
  });

  final WritersideConfigParser configParser;
  final WritersideBuildProfilesParser buildProfilesParser;
  final WritersideInstanceGroupsParser instanceGroupsParser;
  final WritersideTreeParser treeParser;
  final WritersideTreeResolver treeResolver;
  final WritersideTopicParser topicParser;
  final WritersideVariablesParser variablesParser;
  final WritersideCategoriesParser categoriesParser;
  final WorkspaceScanOptions scanOptions;

  Future<WritersideModule> load(
    String rootPath, {
    WorkspaceScanOptions? options,
  }) async {
    final effectiveScanOptions = options ?? scanOptions;
    var root = normalizePath(rootPath);
    final diagnostics = <Diagnostic>[];
    final CanonicalPathAnchor anchor;
    try {
      anchor = await captureCanonicalDirectoryAnchor(root);
      root = anchor.rootPath;
    } on AnchoredPathViolation catch (error) {
      final expectedPath = p.join(root, 'writerside.cfg');
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing',
          severity: DiagnosticSeverity.error,
          filePath: expectedPath,
          args: {'error': '$error'},
        ),
      );
      return _emptyModule(root, expectedPath, diagnostics);
    }
    final configCandidate = await _resolveConfigPath(root);
    if (configCandidate == null) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing',
          severity: DiagnosticSeverity.error,
          filePath: p.join(root, 'writerside.cfg'),
        ),
      );
      return _emptyModule(root, p.join(root, 'writerside.cfg'), diagnostics);
    }
    final AnchoredPathResolution configResolution;
    try {
      configResolution = await resolveAnchoredPath(
        anchor,
        configCandidate,
        allowRoot: false,
      );
    } on AnchoredPathViolation catch (error) {
      diagnostics.add(
        _unsafeConfiguredPathDiagnostic(
          configPath: configCandidate,
          configuredPath: p.basename(configCandidate),
          kind: 'config',
          error: error,
        ),
      );
      return _emptyModule(root, configCandidate, diagnostics);
    }
    if (configResolution.type != FileSystemEntityType.file) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing',
          severity: DiagnosticSeverity.error,
          filePath: configResolution.path,
        ),
      );
      return _emptyModule(root, configResolution.path, diagnostics);
    }
    final configPath = configResolution.path;
    final configSource = await _readFileForParsing(
      File(configPath),
      diagnostics,
      effectiveScanOptions,
      readFailureCode: 'workspace.file.read-failed',
    );
    if (configSource == null) {
      return _emptyModule(root, configPath, diagnostics);
    }
    final config = configParser.parse(configPath, configSource);
    diagnostics.addAll(config.diagnostics);
    final usableTopicRoots = await _existingTopicRoots(
      diagnostics,
      anchor,
      config,
      configPath,
      configSource,
    );
    final validatedImageDirs = await _validateImageRoots(
      diagnostics,
      anchor,
      config,
      configPath,
      configSource,
    );
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      anchor,
      config.buildConfigDir,
      configPath: configPath,
      configSource: configSource,
      kind: 'buildConfig',
      explicit: config.buildConfigExplicit,
      code: 'writerside.config.missing-build-config-directory',
      severity: DiagnosticSeverity.info,
    );
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      anchor,
      config.apiSpecificationsDir,
      configPath: configPath,
      configSource: configSource,
      kind: 'apiSpecifications',
      explicit: config.apiSpecificationsExplicit,
      code: 'writerside.config.missing-api-specifications-directory',
      severity: DiagnosticSeverity.info,
    );
    await _validateOptionalConfiguredDirectory(
      diagnostics,
      anchor,
      config.snippetsDir,
      configPath: configPath,
      configSource: configSource,
      kind: 'snippets',
      explicit: config.snippetsDir != null,
      code: 'writerside.config.missing-snippets-directory',
      severity: DiagnosticSeverity.warning,
    );
    final variablesResolution = await _validateOptionalConfiguredFile(
      diagnostics,
      anchor,
      config.varsFile,
      configPath: configPath,
      configSource: configSource,
      kind: 'variables',
      code: 'writerside.config.missing-vars-file',
    );
    final categoriesResolution = await _validateOptionalConfiguredFile(
      diagnostics,
      anchor,
      config.categoriesFile,
      configPath: configPath,
      configSource: configSource,
      kind: 'categories',
      code: 'writerside.config.missing-categories-file',
    );
    final instanceGroupsResolution = await _validateOptionalConfiguredFile(
      diagnostics,
      anchor,
      config.instanceGroupsFile,
      configPath: configPath,
      configSource: configSource,
      kind: 'instanceGroups',
      code: 'writerside.config.missing-instance-groups-file',
    );
    await _validateConfiguredPathSafety(
      diagnostics,
      anchor,
      config.resourcesFile,
      configPath: configPath,
      configSource: configSource,
      kind: 'resourcesFile',
      allowRoot: false,
    );
    await _validateConfiguredPathSafety(
      diagnostics,
      anchor,
      config.resourcesDir,
      configPath: configPath,
      configSource: configSource,
      kind: 'resourcesDirectory',
      allowRoot: true,
    );

    WritersideBuildProfilesConfig? buildProfiles;
    final buildProfilesResolution = await _resolveConfiguredPath(
      diagnostics,
      anchor,
      p.join(config.buildConfigDir, 'buildprofiles.xml'),
      configPath: configPath,
      configSource: configSource,
      kind: 'buildProfiles',
      allowRoot: false,
    );
    if (buildProfilesResolution?.type == FileSystemEntityType.file) {
      final buildProfilesSource = await _readFileForParsing(
        File(buildProfilesResolution!.path),
        diagnostics,
        effectiveScanOptions,
        readFailureCode: 'workspace.file.read-failed',
      );
      if (buildProfilesSource != null) {
        buildProfiles = buildProfilesParser.parse(
          buildProfilesResolution.path,
          buildProfilesSource,
        );
        diagnostics.addAll(buildProfiles.diagnostics);
      }
    }

    WritersideInstanceGroupsConfig? instanceGroups;
    if (instanceGroupsResolution?.type == FileSystemEntityType.file) {
      final groupsSource = await _readFileForParsing(
        File(instanceGroupsResolution!.path),
        diagnostics,
        effectiveScanOptions,
        readFailureCode: 'workspace.file.read-failed',
      );
      if (groupsSource != null) {
        instanceGroups = instanceGroupsParser.parse(
          instanceGroupsResolution.path,
          groupsSource,
        );
        diagnostics.addAll(instanceGroups.diagnostics);
      }
    }

    var instances = <WritersideInstance>[];
    for (final configuredInstance in config.instances) {
      final source = configuredInstance.src;
      final resolution = await _resolveConfiguredPath(
        diagnostics,
        anchor,
        source,
        configPath: configPath,
        configSource: configSource,
        kind: 'instanceTree',
        allowRoot: false,
      );
      if (resolution == null) {
        continue;
      }
      final treePath = resolution.path;
      if (resolution.type != FileSystemEntityType.file) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.missing-instance-tree',
            severity: DiagnosticSeverity.error,
            filePath: configPath,
            args: {'source': source},
            sourceSpan: _stringSpan(configPath, configSource, source),
          ),
        );
        continue;
      }
      final treeSource = await _readFileForParsing(
        File(treePath),
        diagnostics,
        effectiveScanOptions,
        readFailureCode: 'workspace.file.read-failed',
      );
      if (treeSource == null) {
        continue;
      }
      final parsedInstance = treeParser.parse(treePath, treeSource);
      diagnostics.addAll(parsedInstance.diagnostics);
      instances.add(
        WritersideInstance(
          id: parsedInstance.id,
          name: parsedInstance.name,
          sourceTreePath: parsedInstance.sourceTreePath,
          startPage: parsedInstance.startPage,
          status: parsedInstance.status,
          isLibrary: parsedInstance.isLibrary,
          tocRoots: parsedInstance.tocRoots,
          diagnostics: parsedInstance.diagnostics,
          version: configuredInstance.version,
          globalVersion: config.version,
          webPath: configuredInstance.webPath,
          keymapsMode: configuredInstance.keymapsMode,
          allowSearchEngineIndexing:
              buildProfiles?.allowsSearchEngineIndexing(parsedInstance.id) ??
              false,
          offlineArtifact:
              buildProfiles?.createsOfflineArtifact(parsedInstance.id) ?? false,
          treeEntries: parsedInstance.treeEntries,
        ),
      );
    }
    final treeResolution = treeResolver.resolve(
      moduleRoot: root,
      instances: instances,
      instanceGroups: instanceGroups,
    );
    instances = treeResolution.instances;
    diagnostics.addAll(treeResolution.diagnostics);

    final topics = <WritersideTopic>[];
    final unparsedTopics = _UnparsedTopicIndex();
    var parsedDocuments = 0;
    for (final topicsRoot in usableTopicRoots) {
      final scan = await scanWorkspaceEntities(
        topicsRoot,
        options: effectiveScanOptions,
      );
      diagnostics.addAll(scan.diagnostics);
      for (final entity in scan.entities.whereType<File>()) {
        final extension = p.extension(entity.path).toLowerCase();
        if (extension != '.md' &&
            extension != '.markdown' &&
            extension != '.topic') {
          continue;
        }
        final topicFileName = normalizedRelative(topicsRoot, entity.path);
        if (parsedDocuments >= effectiveScanOptions.maxParsedDocuments) {
          diagnostics.add(
            Diagnostic(
              code: 'workspace.scan.document-limit',
              severity: DiagnosticSeverity.warning,
              filePath: entity.path,
            ),
          );
          unparsedTopics.add(topicFileName);
          continue;
        }
        final source = await _readFileForParsing(
          entity,
          diagnostics,
          effectiveScanOptions,
          readFailureCode: 'writerside.topic.read-failed',
        );
        if (source == null) {
          unparsedTopics.add(topicFileName);
          continue;
        }
        parsedDocuments++;
        try {
          if (extension == '.md' || extension == '.markdown') {
            final topic = topicParser.parseMarkdown(
              filePath: entity.path,
              source: source,
              topicsRoot: topicsRoot,
            );
            diagnostics.addAll(topic.diagnostics);
            topics.add(topic);
          } else {
            final topic = topicParser.parseXml(
              filePath: entity.path,
              source: source,
              topicsRoot: topicsRoot,
            );
            diagnostics.addAll(topic.diagnostics);
            topics.add(topic);
          }
        } on Object catch (error) {
          unparsedTopics.add(topicFileName);
          diagnostics.add(
            Diagnostic(
              code: 'writerside.topic.read-failed',
              severity: DiagnosticSeverity.warning,
              filePath: entity.path,
              args: {'error': '$error'},
            ),
          );
        }
      }
    }

    final variables = <WritersideVariable>[];
    var validateVariables = true;
    if (variablesResolution?.type == FileSystemEntityType.file) {
      final file = File(variablesResolution!.path);
      if (await file.exists()) {
        final source = await _readFileForParsing(
          file,
          diagnostics,
          effectiveScanOptions,
          readFailureCode: 'workspace.file.read-failed',
        );
        if (source == null) {
          validateVariables = false;
        } else {
          final parsed = variablesParser.parse(file.path, source);
          variables.addAll(parsed.$1);
          diagnostics.addAll(parsed.$2);
        }
      }
    }
    final categories = <WritersideCategory>[];
    var validateCategories = true;
    if (categoriesResolution?.type == FileSystemEntityType.file) {
      final file = File(categoriesResolution!.path);
      if (await file.exists()) {
        final source = await _readFileForParsing(
          file,
          diagnostics,
          effectiveScanOptions,
          readFailureCode: 'workspace.file.read-failed',
        );
        if (source == null) {
          validateCategories = false;
        } else {
          final parsed = categoriesParser.parse(file.path, source);
          categories.addAll(parsed.$1);
          diagnostics.addAll(parsed.$2);
        }
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
      validatedImageDirs: validatedImageDirs,
      buildProfiles: buildProfiles,
      instanceGroups: instanceGroups,
    );
    diagnostics.addAll(
      _resolve(
        module,
        validatedImageDirs,
        unparsedTopics: unparsedTopics,
        validateVariables: validateVariables,
        validateCategories: validateCategories,
      ),
    );
    return WritersideModule(
      rootPath: module.rootPath,
      config: module.config,
      instances: module.instances,
      topics: module.topics,
      variables: module.variables,
      categories: module.categories,
      diagnostics: sortDiagnostics(diagnostics),
      validatedImageDirs: module.validatedImageDirs,
      buildProfiles: module.buildProfiles,
      instanceGroups: module.instanceGroups,
    );
  }

  Future<String?> _resolveConfigPath(String root) async {
    final configPath = p.join(root, 'writerside.cfg');
    final configType = await FileSystemEntity.type(
      configPath,
      followLinks: false,
    );
    if (configType == FileSystemEntityType.file ||
        configType == FileSystemEntityType.link) {
      return configPath;
    }
    final legacyPath = p.join(root, 'project.ihp');
    final legacyType = await FileSystemEntity.type(
      legacyPath,
      followLinks: false,
    );
    if (legacyType == FileSystemEntityType.file ||
        legacyType == FileSystemEntityType.link) {
      return legacyPath;
    }
    return null;
  }

  WritersideModule _emptyModule(
    String root,
    String configPath,
    List<Diagnostic> diagnostics,
  ) {
    final emptyConfig = WritersideConfig(
      filePath: configPath,
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
      diagnostics: sortDiagnostics(diagnostics),
      validatedImageDirs: const ['images'],
    );
  }

  Future<String?> _readFileForParsing(
    File file,
    List<Diagnostic> diagnostics,
    WorkspaceScanOptions options, {
    required String readFailureCode,
  }) async {
    final maxBytes = options.maxParsedFileBytes;
    if (maxBytes < 0) {
      diagnostics.add(_fileTooLargeDiagnostic(file.path));
      return null;
    }
    try {
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, maxBytes + 1)) {
        bytes.add(chunk);
      }
      if (bytes.length > maxBytes) {
        diagnostics.add(_fileTooLargeDiagnostic(file.path));
        return null;
      }
      return utf8.decode(bytes.takeBytes());
    } on Object catch (error) {
      diagnostics.add(
        Diagnostic(
          code: readFailureCode,
          severity: DiagnosticSeverity.warning,
          filePath: file.path,
          args: {'error': '$error'},
        ),
      );
      return null;
    }
  }

  Diagnostic _fileTooLargeDiagnostic(String filePath) {
    return Diagnostic(
      code: 'workspace.file.too-large',
      severity: DiagnosticSeverity.warning,
      filePath: filePath,
    );
  }

  Future<List<String>> _existingTopicRoots(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    WritersideConfig config,
    String configPath,
    String configSource,
  ) async {
    final existing = <String>[];
    for (final topicRoot in config.topicRoots) {
      final resolution = await _resolveConfiguredPath(
        diagnostics,
        anchor,
        topicRoot.dir,
        configPath: configPath,
        configSource: configSource,
        kind: 'topics',
        allowRoot: true,
      );
      if (resolution == null) {
        continue;
      }
      if (resolution.type == FileSystemEntityType.directory) {
        existing.add(resolution.path);
        continue;
      }
      if (topicRoot.explicit) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.config.missing-directory',
            severity: DiagnosticSeverity.error,
            filePath: resolution.path,
            args: {'kind': 'topics', 'relativePath': topicRoot.dir},
          ),
        );
      }
    }
    if (existing.isEmpty &&
        config.topicRoots.any(
          (root) => !root.explicit && root.dir == 'topics',
        )) {
      final path = p.join(anchor.rootPath, 'topics');
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing-directory',
          severity: DiagnosticSeverity.error,
          filePath: path,
          args: {'kind': 'topicsDefault', 'relativePath': 'topics'},
        ),
      );
    }
    return existing;
  }

  Future<List<String>> _validateImageRoots(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    WritersideConfig config,
    String configPath,
    String configSource,
  ) async {
    final validated = <String>[];
    for (final imageRoot in config.imageRoots) {
      final resolution = await _resolveConfiguredPath(
        diagnostics,
        anchor,
        imageRoot.dir,
        configPath: configPath,
        configSource: configSource,
        kind: 'images',
        allowRoot: true,
      );
      if (resolution == null) {
        continue;
      }
      validated.add(
        p.normalize(p.relative(resolution.path, from: anchor.rootPath)),
      );
      if (resolution.type == FileSystemEntityType.directory) {
        continue;
      }
      diagnostics.add(
        Diagnostic(
          code: 'writerside.config.missing-directory',
          severity: imageRoot.explicit
              ? DiagnosticSeverity.warning
              : DiagnosticSeverity.info,
          filePath: resolution.path,
          args: {'kind': 'images', 'relativePath': imageRoot.dir},
        ),
      );
    }
    return validated.isEmpty ? const ['images'] : validated.toSet().toList();
  }

  Future<AnchoredPathResolution?> _validateOptionalConfiguredDirectory(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    String? relativePath, {
    required String configPath,
    required String configSource,
    required String kind,
    required bool explicit,
    required String code,
    required DiagnosticSeverity severity,
  }) async {
    if (!explicit || relativePath == null || relativePath.isEmpty) {
      return null;
    }
    final resolution = await _resolveConfiguredPath(
      diagnostics,
      anchor,
      relativePath,
      configPath: configPath,
      configSource: configSource,
      kind: kind,
      allowRoot: true,
    );
    if (resolution == null ||
        resolution.type == FileSystemEntityType.directory) {
      return resolution;
    }
    diagnostics.add(
      Diagnostic(
        code: code,
        severity: severity,
        filePath: resolution.path,
        args: {'relativePath': relativePath},
      ),
    );
    return resolution;
  }

  Future<AnchoredPathResolution?> _validateOptionalConfiguredFile(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    String? relativePath, {
    required String configPath,
    required String configSource,
    required String kind,
    required String code,
  }) async {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    final resolution = await _resolveConfiguredPath(
      diagnostics,
      anchor,
      relativePath,
      configPath: configPath,
      configSource: configSource,
      kind: kind,
      allowRoot: false,
    );
    if (resolution == null || resolution.type == FileSystemEntityType.file) {
      return resolution;
    }
    diagnostics.add(
      Diagnostic(
        code: code,
        severity: DiagnosticSeverity.warning,
        filePath: resolution.path,
        args: {'relativePath': relativePath},
      ),
    );
    return resolution;
  }

  Future<void> _validateConfiguredPathSafety(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    String? configuredPath, {
    required String configPath,
    required String configSource,
    required String kind,
    required bool allowRoot,
  }) async {
    if (configuredPath == null || configuredPath.isEmpty) {
      return;
    }
    await _resolveConfiguredPath(
      diagnostics,
      anchor,
      configuredPath,
      configPath: configPath,
      configSource: configSource,
      kind: kind,
      allowRoot: allowRoot,
    );
  }

  Future<AnchoredPathResolution?> _resolveConfiguredPath(
    List<Diagnostic> diagnostics,
    CanonicalPathAnchor anchor,
    String configuredPath, {
    required String configPath,
    required String configSource,
    required String kind,
    required bool allowRoot,
  }) async {
    final candidate = p.isAbsolute(configuredPath)
        ? p.normalize(configuredPath)
        : p.normalize(p.join(anchor.rootPath, configuredPath));
    try {
      return await resolveAnchoredPath(
        anchor,
        candidate,
        allowRoot: allowRoot,
        allowMissingAncestors: true,
      );
    } on AnchoredPathViolation catch (error) {
      diagnostics.add(
        _unsafeConfiguredPathDiagnostic(
          configPath: configPath,
          configSource: configSource,
          configuredPath: configuredPath,
          kind: kind,
          error: error,
        ),
      );
      return null;
    }
  }

  Diagnostic _unsafeConfiguredPathDiagnostic({
    required String configPath,
    String? configSource,
    required String configuredPath,
    required String kind,
    required AnchoredPathViolation error,
  }) {
    return Diagnostic(
      code: 'writerside.config.path-unsafe',
      severity: DiagnosticSeverity.error,
      filePath: configPath,
      args: {'path': configuredPath, 'kind': kind, 'reason': error.reason.name},
      sourceSpan: configSource == null
          ? null
          : _stringSpan(configPath, configSource, configuredPath),
    );
  }

  List<Diagnostic> _resolve(
    WritersideModule module,
    List<String> validatedImageDirs, {
    required _UnparsedTopicIndex unparsedTopics,
    required bool validateVariables,
    required bool validateCategories,
  }) {
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
          filePath: topic.filePath,
          args: {'id': topic.id},
        ),
      );
    }
    final instanceIds = <String, WritersideInstance>{};
    for (final instance in module.instances) {
      final previous = instanceIds[instance.id];
      if (previous == null) {
        instanceIds[instance.id] = instance;
        continue;
      }
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.duplicate-instance-id',
          severity: DiagnosticSeverity.error,
          filePath: instance.sourceTreePath,
          args: {'id': instance.id},
          relatedSpans: [SourceSpan.entireFile(previous.sourceTreePath, '')],
        ),
      );
    }
    for (final instance in module.instances) {
      if (!instance.isLibrary &&
          instance.startPage == null &&
          instance.tocRoots.isEmpty &&
          instance.navigationTocRoots
              .expand((node) => node.flatten())
              .any((node) => node.topicReference != null)) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.tree.missing-start-page',
            severity: DiagnosticSeverity.error,
            filePath: instance.sourceTreePath,
          ),
        );
      }
      if (instance.startPage != null) {
        final resolved = _resolveTopicReference(module, instance.startPage!);
        if (resolved.isMissing &&
            !unparsedTopics.matches(instance.startPage!)) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.tree.missing-start-page',
              severity: DiagnosticSeverity.error,
              filePath: instance.sourceTreePath,
              args: {'startPage': instance.startPage},
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
      for (final node in instance.navigationTocRoots.expand(
        (node) => node.flatten(),
      )) {
        final referencedInstanceId = node.referenceInstanceId;
        if (node.referenceTopicFileName != null &&
            referencedInstanceId != null &&
            node.origin == null) {
          final referencedInstance = instanceIds[referencedInstanceId];
          if (referencedInstance == null) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.tree.missing-reference-instance',
                severity: DiagnosticSeverity.error,
                filePath: instance.sourceTreePath,
                args: {'instance': referencedInstanceId},
                sourceSpan: node.span,
              ),
            );
          } else {
            final resolvedReference = _resolveTopicReference(
              module,
              node.referenceTopicFileName!,
            );
            final referencedFileName = resolvedReference.topic?.fileName;
            if (referencedFileName == null ||
                !referencedInstance.topicFileSet.contains(referencedFileName)) {
              diagnostics.add(
                Diagnostic(
                  code: 'writerside.tree.missing-reference-topic',
                  severity: DiagnosticSeverity.error,
                  filePath: instance.sourceTreePath,
                  args: {
                    'topic': node.referenceTopicFileName!,
                    'instance': referencedInstanceId,
                  },
                  sourceSpan: node.span,
                ),
              );
            }
          }
        }
        final topic = node.topicFileName;
        if (topic != null && node.origin == null) {
          final resolved = _resolveTopicReference(module, topic);
          if (resolved.isMissing && !unparsedTopics.matches(topic)) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.tree.missing-topic',
                severity: DiagnosticSeverity.error,
                filePath: instance.sourceTreePath,
                args: {'topic': topic},
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
              filePath: instance.sourceTreePath,
              args: {'href': href},
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
            filePath: topic.filePath,
            args: {'fileName': topic.fileName},
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
              filePath: topic.filePath,
              args: {'elementId': id.id},
              sourceSpan: id.span,
              relatedSpans: [duplicateIds[id.id]!],
            ),
          );
        }
        duplicateIds[id.id] = id.span;
      }
      if (validateVariables) {
        for (final variable in topic.variables) {
          if (!variableNames.contains(variable.name)) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.variable.unresolved',
                severity: DiagnosticSeverity.warning,
                filePath: topic.filePath,
                args: {'name': variable.name},
                sourceSpan: variable.span,
              ),
            );
          }
        }
      }
      for (final link in topic.links) {
        final destination = link.destination;
        if (hasUriScheme(destination)) {
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
          if (resolved.isMissing &&
              unparsedTopics.matches(targetReference, fromTopic: topic)) {
            continue;
          }
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
                    filePath: topic.filePath,
                    args: {'destination': destination},
                    sourceSpan: link.span,
                  ),
          );
        } else if (anchor != null && anchor.isNotEmpty) {
          final decodedAnchor = _decodeMarkdownAnchor(anchor);
          final anchors = target.elementIds.map((item) => item.id).toSet();
          if (!anchors.contains(decodedAnchor)) {
            diagnostics.add(
              Diagnostic(
                code: 'markdown.link.unresolved-anchor',
                severity: DiagnosticSeverity.warning,
                filePath: topic.filePath,
                args: {'anchor': anchor, 'targetName': target.fileName},
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
              filePath: topic.filePath,
              args: {'destination': image.destination},
              sourceSpan: image.span,
            ),
          );
        }
        if (hasUriScheme(image.destination)) {
          continue;
        }
        if (!_localImageExistsInAnyRoot(
          module,
          topic,
          image.destination,
          validatedImageDirs,
        )) {
          diagnostics.add(
            Diagnostic(
              code: 'markdown.image.missing-file',
              severity: DiagnosticSeverity.error,
              filePath: topic.filePath,
              args: {'destination': image.destination},
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
          if (resolved.isMissing &&
              unparsedTopics.matches(include.from!, fromTopic: topic)) {
            continue;
          }
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
                      filePath: topic.filePath,
                      args: {'from': include.from},
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
                filePath: topic.filePath,
                args: {'elementId': include.elementId, 'from': include.from},
                sourceSpan: include.span,
              ),
            );
          }
        }
      }
      if (validateCategories) {
        for (final categoryRef in RegExp(
          r'<category\b[^>]*ref="([^"]+)"',
        ).allMatches(topic.markdown?.source ?? '')) {
          final ref = categoryRef.group(1)!;
          if (!categoryIds.contains(ref)) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.category.unresolved',
                severity: DiagnosticSeverity.warning,
                filePath: topic.filePath,
                args: {'ref': ref},
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
    }
    return diagnostics;
  }

  bool _validExternalHref(String href) {
    final uri = parseSchemedUri(href);
    return uri != null && isLaunchableExternalUri(uri);
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
      filePath: filePath,
      args: {'reference': reference},
      sourceSpan: sourceSpan,
    );
  }

  bool _localImageExistsInAnyRoot(
    WritersideModule module,
    WritersideTopic topic,
    String destination,
    List<String> validatedImageDirs,
  ) {
    for (final imagesDir in validatedImageDirs) {
      if (localImageExists(
        activeFilePath: topic.filePath,
        destination: destination,
        workspaceRoot: topic.topicRoot,
        writersideRoot: module.rootPath,
        imagesDir: imagesDir,
      )) {
        return true;
      }
    }
    return false;
  }

  String _decodeMarkdownAnchor(String value) {
    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
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

class _UnparsedTopicIndex {
  final _fileNames = <String>{};
  final _baseNames = <String>{};

  void add(String fileName) {
    _fileNames.add(fileName);
    _baseNames.add(p.basename(fileName));
  }

  bool matches(String reference, {WritersideTopic? fromTopic}) {
    final normalized = p.normalize(reference.trim()).replaceAll(r'\', '/');
    if (normalized.isEmpty) {
      return false;
    }
    if (_fileNames.contains(normalized)) {
      return true;
    }
    if (fromTopic != null && !p.isAbsolute(normalized)) {
      final relative = p
          .normalize(p.join(p.dirname(fromTopic.fileName), normalized))
          .replaceAll(r'\', '/');
      if (_fileNames.contains(relative)) {
        return true;
      }
    }
    return _baseNames.contains(p.basename(normalized));
  }
}
