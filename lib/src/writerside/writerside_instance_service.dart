import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../core/uri_utils.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import 'writerside_model.dart';
import 'writerside_parsers.dart';
import 'writerside_project_creator.dart';

enum WritersideInstanceStatus { release, eap, deprecated }

extension WritersideInstanceStatusValue on WritersideInstanceStatus {
  String get xmlValue => name;

  static WritersideInstanceStatus fromXml(String value) {
    return WritersideInstanceStatus.values.firstWhere(
      (status) => status.xmlValue == value,
      orElse: () => WritersideInstanceStatus.release,
    );
  }
}

class WritersideInstanceSettings {
  const WritersideInstanceSettings({
    required this.name,
    required this.id,
    this.version,
    this.webPath,
    this.status = WritersideInstanceStatus.release,
    this.allowSearchEngineIndexing = false,
    this.offlineArtifact = false,
  });

  final String name;
  final String id;
  final String? version;
  final String? webPath;
  final WritersideInstanceStatus status;
  final bool allowSearchEngineIndexing;
  final bool offlineArtifact;
}

class WritersideMarkdownImportCandidate {
  const WritersideMarkdownImportCandidate({
    required this.absolutePath,
    required this.relativePath,
    required this.title,
  });

  final String absolutePath;
  final String relativePath;
  final String title;
}

class WritersideInstanceCreateRequest {
  const WritersideInstanceCreateRequest({
    required this.settings,
    this.isLibrary = false,
    this.importRootPath,
    this.importedMarkdownPaths = const [],
    this.copyReferencedMedia = true,
  });

  final WritersideInstanceSettings settings;
  final bool isLibrary;
  final String? importRootPath;
  final List<String> importedMarkdownPaths;
  final bool copyReferencedMedia;

  bool get importsMarkdown => importedMarkdownPaths.isNotEmpty;
}

class WritersideInstanceUpdateRequest {
  const WritersideInstanceUpdateRequest({
    required this.treePath,
    required this.settings,
  });

  final String treePath;
  final WritersideInstanceSettings settings;
}

class WritersideInstanceMutationResult {
  const WritersideInstanceMutationResult({
    required this.treePath,
    this.firstTopicPath,
    this.previousId,
  });

  final String treePath;
  final String? firstTopicPath;
  final String? previousId;
}

/// Creates and edits Writerside instances without rewriting topic source.
///
/// The project configuration, tree, build profile, and any ID references are
/// published as one guarded mutation. Every target is checked immediately
/// before publication and a partial publication is rolled back on failure.
class WritersideInstanceService {
  const WritersideInstanceService({
    this.markdownParser = const MarkdownParser(),
    this.buildProfilesParser = const WritersideBuildProfilesParser(),
    Future<void> Function()? beforePublish,
  }) : _beforePublish = beforePublish;

  final MarkdownParser markdownParser;
  final WritersideBuildProfilesParser buildProfilesParser;
  final Future<void> Function()? _beforePublish;

  Future<List<WritersideMarkdownImportCandidate>> discoverMarkdownFiles(
    String sourceDirectoryPath,
  ) async {
    final anchor = await _directoryAnchor(
      sourceDirectoryPath,
      errorCode: 'writerside.instance.import-source-missing',
    );
    final scan = await scanWorkspaceEntities(
      anchor.rootPath,
      options: const WorkspaceScanOptions(
        maxTreeEntries: 20000,
        maxParsedDocuments: 10000,
      ),
    );
    if (scan.diagnostics.isNotEmpty) {
      throw const BusyMarkException(
        'writerside.instance.configuration-invalid',
      );
    }
    final candidates = <WritersideMarkdownImportCandidate>[];
    for (final file in scan.entities.whereType<File>()) {
      if (!isMarkdownPath(file.path)) {
        continue;
      }
      final resolution = await _resolve(anchor, file.path, allowRoot: false);
      if (resolution.type != FileSystemEntityType.file) {
        continue;
      }
      final source = await File(resolution.path).readAsString();
      final parsed = markdownParser.parse(
        filePath: resolution.path,
        source: source,
        mode: MarkdownMode.writersideMarkdown,
        validateLocalReferences: false,
      );
      candidates.add(
        WritersideMarkdownImportCandidate(
          absolutePath: resolution.path,
          relativePath: normalizedRelative(anchor.rootPath, resolution.path),
          title: parsed.title?.trim().isNotEmpty == true
              ? parsed.title!.trim()
              : p.basenameWithoutExtension(resolution.path),
        ),
      );
    }
    candidates.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return List.unmodifiable(candidates);
  }

  Future<WritersideInstanceMutationResult> create({
    required WritersideModule module,
    required WritersideInstanceCreateRequest request,
  }) async {
    final settings = _validatedSettings(request.settings);
    if (request.isLibrary && request.importsMarkdown) {
      throw const BusyMarkException(
        'writerside.instance.library-cannot-import',
      );
    }
    _ensureUniqueId(module, settings.id);
    final rootAnchor = await _moduleAnchor(module.rootPath);
    final configPath = await _existingFilePath(
      rootAnchor,
      module.config.filePath,
      errorCode: 'writerside.instance.config-missing',
    );
    final treePath = (await _resolve(
      rootAnchor,
      p.join(rootAnchor.rootPath, '${settings.id}.tree'),
      allowRoot: false,
    )).path;
    if (await FileSystemEntity.type(treePath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.instance.tree-exists',
        args: {'path': treePath},
      );
    }

    final writes = <String, _DesiredFile>{};
    final configSource = await File(configPath).readAsString();
    final configDocument = XmlDocument.parse(configSource);
    _appendConfiguredInstance(configDocument.rootElement, settings);
    writes[configPath] = _DesiredFile.text(_xml(configDocument));

    final imported = request.importsMarkdown
        ? await _prepareImport(rootAnchor, module, request)
        : const _PreparedImport.empty();
    for (final entry in imported.files.entries) {
      writes[entry.key] = entry.value;
    }
    writes[treePath] = _DesiredFile.text(
      _newTree(
        settings: settings,
        isLibrary: request.isLibrary,
        topicPaths: imported.topicReferences,
      ),
    );

    await _applyBuildSettings(
      writes: writes,
      anchor: rootAnchor,
      module: module,
      oldInstanceId: null,
      settings: settings,
    );
    // Publish registration last so a newly registered instance never points
    // at files that BusyMark has not published yet.
    final desiredConfig = writes.remove(configPath)!;
    writes[configPath] = desiredConfig;
    await _MutationTransaction(
      anchor: rootAnchor,
      desired: writes,
      beforePublish: _beforePublish,
    ).commit();
    return WritersideInstanceMutationResult(
      treePath: treePath,
      firstTopicPath: imported.firstTopicPath,
    );
  }

  Future<WritersideInstanceMutationResult> update({
    required WritersideModule module,
    required WritersideInstanceUpdateRequest request,
  }) async {
    final settings = _validatedSettings(request.settings);
    final instance = module.instances
        .where(
          (candidate) => p.equals(candidate.sourceTreePath, request.treePath),
        )
        .singleOrNull;
    if (instance == null) {
      throw const BusyMarkException('writerside.instance.not-found');
    }
    if (settings.id != instance.id) {
      _ensureUniqueId(module, settings.id, exceptTreePath: request.treePath);
    }
    final anchor = await _moduleAnchor(module.rootPath);
    final oldTreePath = await _existingFilePath(
      anchor,
      instance.sourceTreePath,
      errorCode: 'writerside.instance.tree-missing',
    );
    final configPath = await _existingFilePath(
      anchor,
      module.config.filePath,
      errorCode: 'writerside.instance.config-missing',
    );
    final configuredSource = _configuredSourceFor(module, instance);
    final newTreePath = settings.id == instance.id
        ? oldTreePath
        : (await _resolve(
            anchor,
            p.join(p.dirname(oldTreePath), '${settings.id}.tree'),
            allowRoot: false,
          )).path;
    if (!p.equals(newTreePath, oldTreePath) &&
        await FileSystemEntity.type(newTreePath, followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.instance.tree-exists',
        args: {'path': newTreePath},
      );
    }

    final writes = <String, _DesiredFile>{};
    final treeDocument = XmlDocument.parse(
      await File(oldTreePath).readAsString(),
    );
    final treeRoot = treeDocument.rootElement;
    if (treeRoot.name.local != 'instance-profile') {
      throw const BusyMarkException('writerside.instance.tree-invalid');
    }
    treeRoot.setAttribute('id', settings.id);
    treeRoot.setAttribute('name', settings.name);
    _setOptionalAttribute(
      treeRoot,
      'status',
      settings.status == WritersideInstanceStatus.release
          ? null
          : settings.status.xmlValue,
    );
    writes[newTreePath] = _DesiredFile.text(_xml(treeDocument));
    if (!p.equals(newTreePath, oldTreePath)) {
      writes[oldTreePath] = const _DesiredFile.delete();
    }

    final configDocument = XmlDocument.parse(
      await File(configPath).readAsString(),
    );
    final configElement = _configuredInstanceElement(
      configDocument.rootElement,
      configuredSource,
    );
    if (configElement == null) {
      throw const BusyMarkException('writerside.instance.config-entry-missing');
    }
    _writeConfiguredSettings(
      configElement,
      settings,
      src: normalizedRelative(anchor.rootPath, newTreePath),
    );
    writes[configPath] = _DesiredFile.text(_xml(configDocument));

    await _applyBuildSettings(
      writes: writes,
      anchor: anchor,
      module: module,
      oldInstanceId: instance.id,
      settings: settings,
    );
    if (settings.id != instance.id) {
      await _prepareIdReferenceRefactor(
        writes: writes,
        anchor: anchor,
        module: module,
        oldId: instance.id,
        newId: settings.id,
        oldTreePath: oldTreePath,
        newTreePath: newTreePath,
      );
    }
    // Keep writerside.cfg as the final publication in this multi-file change.
    final desiredConfig = writes.remove(configPath)!;
    writes[configPath] = desiredConfig;
    await _MutationTransaction(
      anchor: anchor,
      desired: writes,
      beforePublish: _beforePublish,
    ).commit();
    return WritersideInstanceMutationResult(
      treePath: newTreePath,
      previousId: instance.id,
    );
  }

  WritersideInstanceSettings _validatedSettings(
    WritersideInstanceSettings settings,
  ) {
    final name = settings.name.trim();
    final id = settings.id.trim();
    if (name.isEmpty) {
      throw const BusyMarkException('writerside.instance.name-required');
    }
    if (!WritersideProjectCreator.isValidInstanceId(id)) {
      throw const BusyMarkException('writerside.project.instance-id-invalid');
    }
    final version = _trimmedOrNull(settings.version);
    final webPath = _trimmedOrNull(settings.webPath);
    if (webPath != null && (webPath.contains('\n') || webPath.contains('\r'))) {
      throw const BusyMarkException('writerside.instance.web-path-invalid');
    }
    return WritersideInstanceSettings(
      name: name,
      id: id,
      version: version,
      webPath: webPath,
      status: settings.status,
      allowSearchEngineIndexing: settings.allowSearchEngineIndexing,
      offlineArtifact: settings.offlineArtifact,
    );
  }

  void _ensureUniqueId(
    WritersideModule module,
    String id, {
    String? exceptTreePath,
  }) {
    if (module.instances.any(
      (instance) =>
          instance.id == id &&
          (exceptTreePath == null ||
              !p.equals(instance.sourceTreePath, exceptTreePath)),
    )) {
      throw BusyMarkException(
        'writerside.instance.id-exists',
        args: {'id': id},
      );
    }
  }

  Future<_PreparedImport> _prepareImport(
    CanonicalPathAnchor rootAnchor,
    WritersideModule module,
    WritersideInstanceCreateRequest request,
  ) async {
    final importRoot = request.importRootPath;
    if (importRoot == null || importRoot.trim().isEmpty) {
      throw const BusyMarkException(
        'writerside.instance.import-source-missing',
      );
    }
    final sourceAnchor = await _directoryAnchor(
      importRoot,
      errorCode: 'writerside.instance.import-source-missing',
    );
    final topicsRoot = (await _resolve(
      rootAnchor,
      p.join(rootAnchor.rootPath, module.config.topicsDir),
      allowRoot: false,
      allowMissingAncestors: true,
    )).path;
    final files = <String, _DesiredFile>{};
    final topicReferences = <String>[];
    String? firstTopicPath;
    for (final requestedPath in request.importedMarkdownPaths) {
      final source = await _resolve(
        sourceAnchor,
        requestedPath,
        allowRoot: false,
      );
      if (source.type != FileSystemEntityType.file ||
          !isMarkdownPath(source.path)) {
        throw BusyMarkException(
          'writerside.instance.import-file-invalid',
          args: {'path': source.path},
        );
      }
      final relative = normalizedRelative(sourceAnchor.rootPath, source.path);
      final target = (await _resolve(
        rootAnchor,
        p.join(topicsRoot, relative),
        allowRoot: false,
        allowMissingAncestors: true,
      )).path;
      await _ensureTargetMissing(target);
      final bytes = await File(source.path).readAsBytes();
      files[target] = _DesiredFile(
        bytes: Uint8List.fromList(bytes),
        sourceMode: (await File(source.path).stat()).mode,
      );
      topicReferences.add(relative);
      firstTopicPath ??= target;

      if (request.copyReferencedMedia) {
        final sourceText = utf8.decode(bytes);
        final parsed = markdownParser.parse(
          filePath: source.path,
          source: sourceText,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        );
        for (final mediaPath in _referencedMediaPaths(parsed)) {
          final media = await _resolveReferencedMedia(
            sourceAnchor,
            source.path,
            mediaPath,
          );
          if (media == null) {
            continue;
          }
          final mediaRelative = normalizedRelative(
            sourceAnchor.rootPath,
            media.path,
          );
          final mediaTarget = (await _resolve(
            rootAnchor,
            p.join(topicsRoot, mediaRelative),
            allowRoot: false,
            allowMissingAncestors: true,
          )).path;
          if (files.containsKey(mediaTarget)) {
            continue;
          }
          await _ensureTargetMissing(mediaTarget);
          files[mediaTarget] = _DesiredFile(
            bytes: Uint8List.fromList(await File(media.path).readAsBytes()),
            sourceMode: (await File(media.path).stat()).mode,
          );
        }
      }
    }
    if (topicReferences.isEmpty) {
      throw const BusyMarkException(
        'writerside.instance.import-selection-required',
      );
    }
    return _PreparedImport(
      files: files,
      topicReferences: topicReferences,
      firstTopicPath: firstTopicPath,
    );
  }

  Iterable<String> _referencedMediaPaths(
    ParsedMarkdownDocument document,
  ) sync* {
    for (final image in document.images) {
      yield image.destination;
    }
    for (final link in document.links) {
      if (_mediaExtensions.contains(
        p.extension(_pathWithoutQuery(link.destination)).toLowerCase(),
      )) {
        yield link.destination;
      }
    }
    for (final block in document.xmlBlocks) {
      try {
        final fragment = XmlDocumentFragment.parse(block.rawXml);
        for (final element in fragment.descendants.whereType<XmlElement>()) {
          if (!{'img', 'video', 'source'}.contains(element.name.local)) {
            continue;
          }
          final source = element.getAttribute('src');
          if (source != null) {
            yield source;
          }
        }
      } on XmlParserException {
        // The Markdown parser reports malformed semantic XML separately.
      }
    }
  }

  Future<AnchoredPathResolution?> _resolveReferencedMedia(
    CanonicalPathAnchor sourceAnchor,
    String markdownPath,
    String destination,
  ) async {
    final value = _pathWithoutQuery(destination.trim());
    if (value.isEmpty || hasUriScheme(value) || p.isAbsolute(value)) {
      return null;
    }
    try {
      final resolution = await _resolve(
        sourceAnchor,
        p.join(p.dirname(markdownPath), Uri.decodeComponent(value)),
        allowRoot: false,
      );
      return resolution.type == FileSystemEntityType.file ? resolution : null;
    } on Object {
      return null;
    }
  }

  Future<void> _applyBuildSettings({
    required Map<String, _DesiredFile> writes,
    required CanonicalPathAnchor anchor,
    required WritersideModule module,
    required String? oldInstanceId,
    required WritersideInstanceSettings settings,
  }) async {
    final buildProfilesPath = (await _resolve(
      anchor,
      p.join(
        anchor.rootPath,
        module.config.buildConfigDir,
        'buildprofiles.xml',
      ),
      allowRoot: false,
      allowMissingAncestors: true,
    )).path;
    final existingType = await FileSystemEntity.type(
      buildProfilesPath,
      followLinks: false,
    );
    final source = existingType == FileSystemEntityType.file
        ? await File(buildProfilesPath).readAsString()
        : null;
    final parsed = source == null
        ? WritersideBuildProfilesConfig(filePath: buildProfilesPath)
        : buildProfilesParser.parse(buildProfilesPath, source);
    if (parsed.diagnostics.any(
      (diagnostic) => diagnostic.severity == DiagnosticSeverity.error,
    )) {
      throw const BusyMarkException(
        'writerside.instance.build-profiles-invalid',
      );
    }
    final inheritedNoindex = parsed.globalValues.noindexContent ?? true;
    final inheritedOffline = parsed.globalValues.offlineDocs ?? false;
    final desiredNoindex = !settings.allowSearchEngineIndexing;
    final desiredOffline = settings.offlineArtifact;
    final needsNoindexOverride = desiredNoindex != inheritedNoindex;
    final needsOfflineOverride = desiredOffline != inheritedOffline;
    final oldId = oldInstanceId ?? settings.id;

    if (source == null && !needsNoindexOverride && !needsOfflineOverride) {
      return;
    }
    final document = source == null
        ? XmlDocument.parse(_emptyBuildProfiles())
        : XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'buildprofiles') {
      throw const BusyMarkException(
        'writerside.instance.build-profiles-invalid',
      );
    }
    final profiles = root.childElements
        .where(
          (element) =>
              element.name.local == 'build-profile' &&
              element.getAttribute('instance') == oldId,
        )
        .toList();
    if (profiles.isEmpty && (needsNoindexOverride || needsOfflineOverride)) {
      final profile = XmlElement(XmlName.parts('build-profile'), [
        XmlAttribute(XmlName.parts('instance'), settings.id),
      ]);
      root.children.add(profile);
      profiles.add(profile);
    }
    if (profiles.isEmpty) {
      return;
    }
    for (final profile in profiles) {
      profile.setAttribute('instance', settings.id);
      for (final variables
          in profile.childElements
              .where((element) => element.name.local == 'variables')
              .toList()) {
        _setBuildVariable(variables, 'noindex-content', null);
        _setBuildVariable(variables, 'offline-docs', null);
        _removeEmptyVariables(profile, variables);
      }
    }

    final targetProfile = profiles.first;
    if (needsNoindexOverride || needsOfflineOverride) {
      var variables = targetProfile.childElements
          .where((element) => element.name.local == 'variables')
          .firstOrNull;
      if (variables == null) {
        variables = XmlElement(XmlName.parts('variables'));
        targetProfile.children.add(variables);
      }
      _setBuildVariable(
        variables,
        'noindex-content',
        needsNoindexOverride ? '$desiredNoindex' : null,
      );
      _setBuildVariable(
        variables,
        'offline-docs',
        needsOfflineOverride ? '$desiredOffline' : null,
      );
    }
    for (final profile in profiles.reversed) {
      if (_elementHasNoContent(profile)) {
        root.children.remove(profile);
      }
    }
    writes[buildProfilesPath] = _DesiredFile.text(_xml(document));
  }

  void _removeEmptyVariables(XmlElement profile, XmlElement variables) {
    if (_elementHasNoContent(variables)) {
      profile.children.remove(variables);
    }
  }

  bool _elementHasNoContent(XmlElement element) {
    return element.children.every(
      (node) => node is XmlText && node.value.trim().isEmpty,
    );
  }

  void _setBuildVariable(XmlElement variables, String name, String? value) {
    final existing = variables.childElements
        .where(
          (element) =>
              element.name.local == name &&
              element.getAttribute('status') == null,
        )
        .toList();
    for (final duplicate in existing.skip(1)) {
      variables.children.remove(duplicate);
    }
    if (value == null) {
      if (existing.isNotEmpty) {
        variables.children.remove(existing.first);
      }
      return;
    }
    final target = existing.firstOrNull ?? XmlElement(XmlName.parts(name));
    if (existing.isEmpty) {
      variables.children.add(target);
    }
    target.children
      ..clear()
      ..add(XmlText(value));
  }

  Future<void> _prepareIdReferenceRefactor({
    required Map<String, _DesiredFile> writes,
    required CanonicalPathAnchor anchor,
    required WritersideModule module,
    required String oldId,
    required String newId,
    required String oldTreePath,
    required String newTreePath,
  }) async {
    final scan = await scanWorkspaceEntities(
      anchor.rootPath,
      options: const WorkspaceScanOptions(
        maxTreeEntries: 20000,
        maxParsedDocuments: 10000,
      ),
    );
    final knownXmlPaths = <String>{
      if (module.config.instanceGroupsFile case final groups?)
        p.normalize(p.join(anchor.rootPath, groups)),
      p.join(anchor.rootPath, module.config.buildConfigDir, 'build-groups.xml'),
    };
    for (final file in scan.entities.whereType<File>()) {
      final path = p.normalize(file.path);
      if (p.equals(path, oldTreePath) || writes.containsKey(path)) {
        continue;
      }
      final extension = p.extension(path).toLowerCase();
      final isXml =
          extension == '.tree' ||
          extension == '.topic' ||
          knownXmlPaths.contains(path);
      final isMarkdown = extension == '.md' || extension == '.markdown';
      if (!isXml && !isMarkdown) {
        continue;
      }
      final source = await File(path).readAsString();
      final updated = isXml
          ? _refactorXmlSource(
              source,
              oldId: oldId,
              newId: newId,
              oldTreePath: oldTreePath,
              newTreePath: newTreePath,
              sourcePath: path,
            )
          : _refactorMarkdownSource(source, oldId: oldId, newId: newId);
      if (updated != source) {
        writes[path] = _DesiredFile.text(updated);
      }
    }

    // Some files, notably buildprofiles.xml and writerside.cfg, are already
    // staged by the instance edit and were intentionally skipped above.
    // Refactor every staged XML document as well so auxiliary `instance`
    // attributes cannot retain the old ID.
    for (final entry in writes.entries.toList()) {
      final bytes = entry.value.bytes;
      if (bytes == null ||
          !_isXmlProjectFile(entry.key, module.config.filePath)) {
        continue;
      }
      writes[entry.key] = _DesiredFile.text(
        _refactorXmlSource(
          utf8.decode(bytes),
          oldId: oldId,
          newId: newId,
          oldTreePath: oldTreePath,
          newTreePath: newTreePath,
          sourcePath: entry.key,
        ),
      );
    }
  }

  bool _isXmlProjectFile(String path, String configPath) {
    if (p.equals(path, configPath)) {
      return true;
    }
    return const {
      '.xml',
      '.tree',
      '.topic',
    }.contains(p.extension(path).toLowerCase());
  }

  String _refactorXmlSource(
    String source, {
    required String oldId,
    required String newId,
    required String oldTreePath,
    required String newTreePath,
    required String sourcePath,
  }) {
    XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on XmlParserException {
      throw const BusyMarkException(
        'writerside.instance.configuration-invalid',
      );
    }
    var changed = false;
    for (final element in <XmlElement>[
      document.rootElement,
      ...document.descendants.whereType<XmlElement>(),
    ]) {
      for (final name in const ['instance', 'instances']) {
        final value = element.getAttribute(name);
        if (value == null) {
          continue;
        }
        final updated = _replaceInstanceList(value, oldId, newId);
        if (updated != value) {
          element.setAttribute(name, updated);
          changed = true;
        }
      }
      for (final name in const ['in', 'instance-id']) {
        if (element.getAttribute(name) == oldId) {
          element.setAttribute(name, newId);
          changed = true;
        }
      }
      final from = element.getAttribute('from');
      if (from != null && p.extension(from).toLowerCase() == '.tree') {
        final candidate = p.normalize(
          p.isAbsolute(from) ? from : p.join(p.dirname(sourcePath), from),
        );
        if (p.equals(candidate, oldTreePath)) {
          element.setAttribute(
            'from',
            normalizedRelative(p.dirname(sourcePath), newTreePath),
          );
          changed = true;
        }
      }
    }
    return changed ? _xml(document) : source;
  }

  String _refactorMarkdownSource(
    String source, {
    required String oldId,
    required String newId,
  }) {
    final codeRanges = markdownParser
        .parse(
          filePath: 'instance-refactor.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .codeBlocks
        .map((block) => (block.span.startOffset, block.span.endOffset))
        .toList();
    final pattern = RegExp(
      r'''\b(instance|instances|in|instance-id)\s*=\s*(["'])(.*?)\2''',
      dotAll: true,
    );
    final buffer = StringBuffer();
    var cursor = 0;
    for (final match in pattern.allMatches(source)) {
      if (codeRanges.any(
        (range) => match.start >= range.$1 && match.start < range.$2,
      )) {
        continue;
      }
      if (_insideInlineCode(source, match.start)) {
        continue;
      }
      final name = match.group(1)!;
      final value = match.group(3)!;
      final updated = name == 'in' || name == 'instance-id'
          ? value == oldId
                ? newId
                : value
          : _replaceInstanceList(value, oldId, newId);
      if (updated == value) {
        continue;
      }
      final fullMatch = match.group(0)!;
      final equalsIndex = fullMatch.indexOf('=');
      final quoteIndex = fullMatch.indexOf(match.group(2)!, equalsIndex + 1);
      final valueStart = match.start + quoteIndex + 1;
      buffer
        ..write(source.substring(cursor, valueStart))
        ..write(updated);
      cursor = valueStart + value.length;
    }
    if (cursor == 0) {
      return source;
    }
    buffer.write(source.substring(cursor));
    return buffer.toString();
  }

  bool _insideInlineCode(String source, int offset) {
    final lineStart = source.lastIndexOf('\n', offset - 1) + 1;
    final prefix = source.substring(lineStart, offset);
    var openRun = 0;
    var index = 0;
    while (index < prefix.length) {
      if (prefix.codeUnitAt(index) != 0x60) {
        index++;
        continue;
      }
      var end = index + 1;
      while (end < prefix.length && prefix.codeUnitAt(end) == 0x60) {
        end++;
      }
      final run = end - index;
      openRun = openRun == run ? 0 : run;
      index = end;
    }
    return openRun != 0;
  }

  String _replaceInstanceList(String value, String oldId, String newId) {
    final negated = value.startsWith('!');
    final body = negated ? value.substring(1) : value;
    final values = body.split(',');
    var changed = false;
    final updated = <String>[];
    for (final item in values) {
      final leading = item.substring(0, item.length - item.trimLeft().length);
      final trailing = item.substring(item.trimRight().length);
      final token = item.trim();
      if (token == oldId) {
        updated.add('$leading$newId$trailing');
        changed = true;
      } else {
        updated.add(item);
      }
    }
    return changed ? '${negated ? '!' : ''}${updated.join(',')}' : value;
  }

  String _configuredSourceFor(
    WritersideModule module,
    WritersideInstance instance,
  ) {
    for (final configured in module.config.instances) {
      final path = p.normalize(
        p.isAbsolute(configured.src)
            ? configured.src
            : p.join(module.rootPath, configured.src),
      );
      if (p.equals(path, instance.sourceTreePath)) {
        return configured.src;
      }
    }
    throw const BusyMarkException('writerside.instance.config-entry-missing');
  }

  void _appendConfiguredInstance(
    XmlElement root,
    WritersideInstanceSettings settings,
  ) {
    if (root.name.local != 'ihp') {
      throw const BusyMarkException('writerside.instance.config-invalid');
    }
    final element = XmlElement(XmlName.parts('instance'));
    _writeConfiguredSettings(element, settings, src: '${settings.id}.tree');
    root.children.add(element);
  }

  XmlElement? _configuredInstanceElement(XmlElement root, String source) {
    return root.childElements
        .where(
          (element) =>
              element.name.local == 'instance' &&
              element.getAttribute('src') == source,
        )
        .firstOrNull;
  }

  void _writeConfiguredSettings(
    XmlElement element,
    WritersideInstanceSettings settings, {
    required String src,
  }) {
    element.setAttribute('src', src.replaceAll(r'\', '/'));
    _setOptionalAttribute(element, 'web-path', settings.webPath);
    _setOptionalAttribute(element, 'version', settings.version);
  }

  String _newTree({
    required WritersideInstanceSettings settings,
    required bool isLibrary,
    required List<String> topicPaths,
  }) {
    final attributes = <XmlAttribute>[
      XmlAttribute(XmlName.parts('id'), settings.id),
      XmlAttribute(XmlName.parts('name'), settings.name),
      if (topicPaths.isNotEmpty)
        XmlAttribute(XmlName.parts('start-page'), topicPaths.first),
      if (settings.status != WritersideInstanceStatus.release)
        XmlAttribute(XmlName.parts('status'), settings.status.xmlValue),
      if (isLibrary) XmlAttribute(XmlName.parts('is-library'), 'true'),
    ];
    final root = XmlElement(XmlName.parts('instance-profile'), attributes, [
      for (final topic in topicPaths)
        XmlElement(XmlName.parts('toc-element'), [
          XmlAttribute(XmlName.parts('topic'), topic),
        ]),
    ]);
    final document = XmlDocument.parse(
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<!DOCTYPE instance-profile SYSTEM '
      '"https://resources.jetbrains.com/writerside/1.0/product-profile.dtd">\n'
      '<instance-profile/>',
    );
    document.rootElement.replace(root);
    return _xml(document);
  }

  String _emptyBuildProfiles() {
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE buildprofiles SYSTEM "https://resources.jetbrains.com/writerside/1.0/build-profiles.dtd">\n'
        '<buildprofiles xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="https://resources.jetbrains.com/writerside/1.0/build-profiles.xsd"/>\n';
  }

  void _setOptionalAttribute(XmlElement element, String name, String? value) {
    if (value == null || value.isEmpty) {
      element.removeAttribute(name);
    } else {
      element.setAttribute(name, value);
    }
  }

  String _xml(XmlDocument document) =>
      '${document.toXmlString(pretty: true, indent: '  ')}\n';

  Future<CanonicalPathAnchor> _moduleAnchor(String rootPath) {
    return _directoryAnchor(
      rootPath,
      errorCode: 'writerside.topic.module-root-missing',
    );
  }

  Future<CanonicalPathAnchor> _directoryAnchor(
    String path, {
    required String errorCode,
  }) async {
    try {
      final anchor = await captureCanonicalDirectoryAnchor(normalizePath(path));
      if (!p.equals(anchor.requestedRootPath, anchor.rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootReplacement,
          path: anchor.requestedRootPath,
        );
      }
      return anchor;
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(errorCode, args: {'path': error.path});
    }
  }

  Future<AnchoredPathResolution> _resolve(
    CanonicalPathAnchor anchor,
    String path, {
    required bool allowRoot,
    bool allowMissingAncestors = false,
  }) async {
    try {
      return await resolveAnchoredPath(
        anchor,
        normalizePath(path),
        allowRoot: allowRoot,
        allowMissingAncestors: allowMissingAncestors,
      );
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.instance.path-unsafe',
        args: {'path': error.path},
      );
    }
  }

  Future<String> _existingFilePath(
    CanonicalPathAnchor anchor,
    String path, {
    required String errorCode,
  }) async {
    final resolution = await _resolve(anchor, path, allowRoot: false);
    if (resolution.type != FileSystemEntityType.file) {
      throw BusyMarkException(errorCode, args: {'path': resolution.path});
    }
    return resolution.path;
  }

  Future<void> _ensureTargetMissing(String path) async {
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.instance.import-target-exists',
        args: {'path': path},
      );
    }
  }
}

const _mediaExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.svg',
  '.webp',
  '.avif',
  '.mp4',
  '.webm',
  '.ogg',
  '.mov',
};

String _pathWithoutQuery(String value) {
  final hash = value.indexOf('#');
  final query = value.indexOf('?');
  final indexes = [hash, query].where((index) => index >= 0).toList();
  if (indexes.isEmpty) {
    return value;
  }
  indexes.sort();
  return value.substring(0, indexes.first);
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

class _PreparedImport {
  const _PreparedImport({
    required this.files,
    required this.topicReferences,
    required this.firstTopicPath,
  });

  const _PreparedImport.empty()
    : files = const {},
      topicReferences = const [],
      firstTopicPath = null;

  final Map<String, _DesiredFile> files;
  final List<String> topicReferences;
  final String? firstTopicPath;
}

class _DesiredFile {
  const _DesiredFile({required this.bytes, this.sourceMode});

  const _DesiredFile.delete() : bytes = null, sourceMode = null;

  factory _DesiredFile.text(String value) =>
      _DesiredFile(bytes: Uint8List.fromList(utf8.encode(value)));

  final Uint8List? bytes;
  final int? sourceMode;
}

class _OriginalFile {
  const _OriginalFile({required this.bytes, required this.mode});

  final Uint8List? bytes;
  final int? mode;
}

class _MutationTransaction {
  const _MutationTransaction({
    required this.anchor,
    required this.desired,
    this.beforePublish,
  });

  final CanonicalPathAnchor anchor;
  final Map<String, _DesiredFile> desired;
  final Future<void> Function()? beforePublish;

  Future<void> commit() async {
    final originals = <String, _OriginalFile>{};
    final staged = <String, File>{};
    final published = <String>[];
    final createdDirectories = <Directory>[];
    try {
      for (final entry in desired.entries) {
        final resolution = await resolveAnchoredPath(
          anchor,
          entry.key,
          allowRoot: false,
          allowMissingAncestors: true,
        );
        final type = resolution.type;
        if (type != FileSystemEntityType.file &&
            type != FileSystemEntityType.notFound) {
          throw BusyMarkException(
            'writerside.instance.path-unsafe',
            args: {'path': resolution.path},
          );
        }
        final originalBytes = type == FileSystemEntityType.file
            ? Uint8List.fromList(await File(resolution.path).readAsBytes())
            : null;
        final originalMode = type == FileSystemEntityType.file
            ? (await File(resolution.path).stat()).mode
            : null;
        originals[resolution.path] = _OriginalFile(
          bytes: originalBytes,
          mode: originalMode,
        );
        if (entry.value.bytes == null) {
          continue;
        }
        await _ensureParentDirectories(resolution.path, createdDirectories);
        final temporary = await _temporaryFile(resolution.path);
        await temporary.writeAsBytes(entry.value.bytes!, flush: true);
        await _applyMode(temporary, originalMode ?? entry.value.sourceMode);
        staged[resolution.path] = temporary;
      }

      await beforePublish?.call();
      for (final entry in originals.entries) {
        await _verifyOriginal(entry.key, entry.value);
      }
      for (final entry in desired.entries) {
        final path = p.normalize(entry.key);
        final bytes = entry.value.bytes;
        if (bytes == null) {
          if (await FileSystemEntity.type(path, followLinks: false) ==
              FileSystemEntityType.file) {
            await File(path).delete();
          }
        } else {
          await staged[path]!.rename(path);
        }
        published.add(path);
      }
    } on Object catch (error, stackTrace) {
      final rollbackSucceeded = await _rollback(originals, desired, published);
      if (!rollbackSucceeded) {
        throw BusyMarkException(
          'writerside.instance.rollback-failed',
          args: {'paths': published.join(', ')},
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      for (final file in staged.values) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } on Object {
          // Best-effort cleanup does not replace the transaction result.
        }
      }
      for (final directory in createdDirectories.reversed) {
        try {
          if (await directory.exists() && await directory.list().isEmpty) {
            await directory.delete();
          }
        } on Object {
          // Non-empty or concurrently used directories must remain.
        }
      }
    }
  }

  Future<void> _verifyOriginal(String path, _OriginalFile original) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (original.bytes == null) {
      if (type != FileSystemEntityType.notFound) {
        throw BusyMarkException(
          'writerside.instance.files-changed',
          args: {'path': path},
        );
      }
      return;
    }
    if (type != FileSystemEntityType.file ||
        !_sameBytes(await File(path).readAsBytes(), original.bytes!)) {
      throw BusyMarkException(
        'writerside.instance.files-changed',
        args: {'path': path},
      );
    }
  }

  Future<bool> _rollback(
    Map<String, _OriginalFile> originals,
    Map<String, _DesiredFile> desired,
    List<String> published,
  ) async {
    var succeeded = true;
    for (final path in published.reversed) {
      final original = originals[path]!;
      final expected = desired[path]!.bytes;
      try {
        final type = await FileSystemEntity.type(path, followLinks: false);
        if (expected == null) {
          if (type != FileSystemEntityType.notFound) {
            succeeded = false;
            continue;
          }
        } else if (type != FileSystemEntityType.file ||
            !_sameBytes(await File(path).readAsBytes(), expected)) {
          succeeded = false;
          continue;
        }
        if (original.bytes == null) {
          if (type == FileSystemEntityType.file) {
            await File(path).delete();
          }
          continue;
        }
        final temporary = await _temporaryFile(path);
        try {
          await temporary.writeAsBytes(original.bytes!, flush: true);
          await _applyMode(temporary, original.mode);
          await temporary.rename(path);
        } finally {
          if (await temporary.exists()) {
            await temporary.delete();
          }
        }
      } on Object {
        succeeded = false;
      }
    }
    return succeeded;
  }

  Future<void> _ensureParentDirectories(
    String targetPath,
    List<Directory> created,
  ) async {
    final missing = <Directory>[];
    var current = Directory(p.dirname(targetPath));
    while (!await current.exists() &&
        !p.equals(current.path, anchor.rootPath)) {
      missing.add(current);
      current = current.parent;
    }
    for (final directory in missing.reversed) {
      await directory.create();
      created.add(directory);
    }
  }

  Future<File> _temporaryFile(String targetPath) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = File(
        p.join(
          p.dirname(targetPath),
          '.${p.basename(targetPath)}.busymark-instance-$pid-'
          '${DateTime.now().microsecondsSinceEpoch}-$attempt',
        ),
      );
      try {
        return await candidate.create(exclusive: true);
      } on FileSystemException {
        continue;
      }
    }
    throw BusyMarkException(
      'writerside.instance.temporary-file-failed',
      args: {'path': targetPath},
    );
  }

  Future<void> _applyMode(File file, int? mode) async {
    if (Platform.isWindows || mode == null) {
      return;
    }
    final value = (mode & 0xfff).toRadixString(8);
    final result = await Process.run('chmod', [value, file.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Failed to apply file mode $value: ${result.stderr}',
        file.path,
      );
    }
  }
}

bool _sameBytes(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
