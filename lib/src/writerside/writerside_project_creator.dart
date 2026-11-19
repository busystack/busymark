import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/linux_atomic_file_api.dart';
import '../core/linux_file_identity.dart';
import '../core/path_utils.dart';
import '../core/save_destination.dart';

class WritersideProjectCreateRequest {
  const WritersideProjectCreateRequest({
    required this.parentDirectoryPath,
    required this.projectName,
    required this.directoryName,
    required this.instanceName,
    required this.topicTitle,
    this.moduleName,
    this.instanceId = 'user-guide',
    this.topicFileName,
  });

  final String parentDirectoryPath;
  final String projectName;
  final String directoryName;
  final String? moduleName;
  final String instanceName;
  final String instanceId;
  final String topicTitle;
  final String? topicFileName;
}

class WritersideProjectCreateResult {
  const WritersideProjectCreateResult({
    required this.rootPath,
    required this.configPath,
    required this.treePath,
    required this.startTopicPath,
  });

  final String rootPath;
  final String configPath;
  final String treePath;
  final String startTopicPath;
}

class WritersideProjectCreator {
  const WritersideProjectCreator();

  static final _instanceIdStartPattern = RegExp(r'[\p{L}]', unicode: true);
  static final _instanceIdCharacterPattern = RegExp(
    r'[\p{L}\p{M}\p{N}_-]',
    unicode: true,
  );

  static bool isValidInstanceId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    var index = 0;
    for (final rune in trimmed.runes) {
      final character = String.fromCharCode(rune);
      if (index == 0 && !_instanceIdStartPattern.hasMatch(character)) {
        return false;
      }
      if (!_instanceIdCharacterPattern.hasMatch(character)) {
        return false;
      }
      index += 1;
    }
    return true;
  }

  static String slugInstanceId(String value) {
    final buffer = StringBuffer();
    var pendingSeparator = false;
    for (final rune in value.toLowerCase().trim().runes) {
      final character = String.fromCharCode(rune);
      if (_instanceIdCharacterPattern.hasMatch(character)) {
        if (pendingSeparator && buffer.isNotEmpty) {
          buffer.write('-');
        }
        buffer.write(character);
        pendingSeparator = false;
      } else {
        pendingSeparator = true;
      }
    }
    final slug = buffer.toString().replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    if (slug.isEmpty) {
      return 'user-guide';
    }
    if (!_instanceIdStartPattern.hasMatch(
      String.fromCharCode(slug.runes.first),
    )) {
      return 'instance-$slug';
    }
    return slug;
  }

  Future<WritersideProjectCreateResult> create(
    WritersideProjectCreateRequest request,
  ) async => (await createTransaction(
    request,
    authorize: () async => true,
    canPublish: () => true,
    accept: (project, _) async => project,
  ))!;

  /// Prepare the generated tree privately, and retain ownership until the
  /// caller accepts the project at its final paths. A null result rolls back
  /// publication, for example after a competing navigation or an initial read
  /// failure. An existing empty destination keeps its original directory.
  Future<T?> createTransaction<T>(
    WritersideProjectCreateRequest request, {
    required Future<bool> Function() authorize,
    required bool Function() canPublish,
    required Future<T?> Function(
      WritersideProjectCreateResult,
      bool Function() isCurrent,
    )
    accept,
  }) async {
    final validated = _validate(request);
    final parent = await _parentAnchor(validated.parentDirectoryPath);
    final resolution = await _projectPath(
      parent,
      p.join(parent.rootPath, validated.directoryName),
    );
    final root = Directory(resolution.path);
    if (resolution.type != FileSystemEntityType.notFound &&
        resolution.type != FileSystemEntityType.directory) {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': root.path},
      );
    }
    final destination = SaveDestination.inspect(
      root.path,
      kind: SaveDestinationKind.directory,
    );
    if (destination.replacesExisting && !await _isDirectoryEmpty(root)) {
      throw BusyMarkException(
        'writerside.project.target-directory-not-empty',
        args: {'path': root.path},
      );
    }
    if (!await authorize() || !canPublish()) return null;

    destination.requireCurrent(root.path);
    final parentId = _identity(parent.rootPath);
    final staging = await Directory(
      parent.rootPath,
    ).createTemp('.busymark-writerside-');
    final stagingId = _identity(staging.path);
    final moved = <String>[];
    final entries = <String, String>{};
    final tree = '${validated.instanceId}.tree';
    final topic = p.join('topics', validated.topicFileName);
    final files = {
      'writerside.cfg': _writersideConfig(
        moduleName: validated.moduleName,
        treeFileName: tree,
      ),
      tree: _writersideTree(
        instanceId: validated.instanceId,
        instanceName: validated.instanceName,
        topicFileName: validated.topicFileName,
      ),
      topic: _startTopic(title: validated.topicTitle),
    };
    String? publishedRootId;
    try {
      final stage = await _projectRootAnchor(parent, staging.path);
      if (!_owns(staging.path, stagingId)) {
        throw FileSystemException(
          'Project staging directory changed',
          staging.path,
        );
      }
      const directories = ['topics', 'images', 'cfg'];
      for (final name in directories) {
        await _createProjectDirectory(stage, name);
        entries[name] = _identity(p.join(stage.rootPath, name));
      }
      for (final entry in files.entries) {
        await _writeNewFile(
          stage,
          p.join(stage.rootPath, entry.key),
          entry.value,
        );
        entries[entry.key] = _identity(p.join(stage.rootPath, entry.key));
      }
      if (!canPublish()) return null;
      destination.requireCurrent(root.path);
      if (!_owns(staging.path, stagingId)) {
        throw FileSystemException(
          'Project staging directory changed',
          staging.path,
        );
      }
      if (destination.replacesExisting) {
        publishedRootId = _identity(root.path);
        for (final name in [...directories, 'writerside.cfg', tree]) {
          _publish(
            p.join(stage.rootPath, name),
            p.join(root.path, name),
            directory: directories.contains(name),
          );
          moved.add(name);
        }
      } else {
        _publish(stage.rootPath, root.path, directory: true);
        publishedRootId = stagingId;
        moved.addAll(entries.keys);
      }
      final rootId = publishedRootId;
      bool isCurrent() {
        if (!canPublish()) return false;
        if (!_owns(parent.rootPath, parentId) ||
            !_owns(root.path, rootId) ||
            !entries.entries.every(
              (entry) => _owns(p.join(root.path, entry.key), entry.value),
            )) {
          throw FileSystemException(
            'Generated project changed during creation',
            root.path,
          );
        }
        return true;
      }

      if (!isCurrent()) return null;
      final result = await accept(
        WritersideProjectCreateResult(
          rootPath: root.path,
          configPath: p.join(root.path, 'writerside.cfg'),
          treePath: p.join(root.path, tree),
          startTopicPath: p.join(root.path, topic),
        ),
        isCurrent,
      );
      if (result != null) publishedRootId = null;
      return result;
    } finally {
      final sameParent = _owns(parent.rootPath, parentId);
      if (sameParent &&
          publishedRootId != null &&
          _owns(root.path, publishedRootId)) {
        // Delete only generated entries we actually moved. Checking the
        // directory and file identities protects replacements, and removing
        // directories without recursion preserves any concurrent additions.
        for (final path in files.keys) {
          final top = p.split(path).first;
          if (!moved.contains(top)) continue;
          if (top != path && !_owns(p.join(root.path, top), entries[top]!)) {
            continue;
          }
          final file = File(p.join(root.path, path));
          try {
            if (_owns(file.path, entries[path]!) &&
                file.readAsStringSync() == files[path] &&
                _owns(file.path, entries[path]!)) {
              file.deleteSync();
            }
          } on FileSystemException {
            // A concurrent writer can make a generated entry unsafe to remove.
          } on FormatException {
            // A generated file with changed bytes now belongs to the writer.
          }
        }
        for (final path in moved.where((path) => !files.containsKey(path))) {
          _removeOwnedDirectory(p.join(root.path, path), entries[path]!);
        }
        if (!destination.replacesExisting) {
          _removeOwnedDirectory(root.path, publishedRootId);
        }
      }
      if (sameParent && _owns(staging.path, stagingId)) {
        // createTemp allocated this private tree for this transaction.
        try {
          staging.deleteSync(recursive: true);
        } on FileSystemException {
          // A filesystem failure must not discard an accepted project.
        }
      }
    }
  }

  String _identity(String path) =>
      LinuxFileIdentity.read(path) ??
      (throw FileSystemException('Cannot establish project ownership', path));

  bool _owns(String path, String identity) {
    try {
      return LinuxFileIdentity.read(path) == identity;
    } on FileSystemException {
      return false;
    }
  }

  void _removeOwnedDirectory(String path, String identity) {
    if (!_owns(path, identity)) return;
    try {
      Directory(path).deleteSync();
    } on FileSystemException {
      // A nonempty directory contains data outside this transaction.
    }
  }

  void _publish(String stage, String target, {required bool directory}) {
    final error = LinuxAtomicFileApi.instance.publishNoReplace(
      stage,
      target,
      directory: directory,
    );
    if (error != null) {
      throw FileSystemException(
        'Could not publish the Writerside project',
        target,
        OSError('No-replace publication failed', error),
      );
    }
  }

  Future<CanonicalPathAnchor> _parentAnchor(String path) async {
    try {
      return await captureCanonicalDirectoryAnchor(path);
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.project.parent-directory-missing',
        args: {'path': error.path},
      );
    }
  }

  Future<CanonicalPathAnchor> _projectRootAnchor(
    CanonicalPathAnchor parentAnchor,
    String rootPath,
  ) async {
    try {
      final parentResolution = await resolveAnchoredPath(
        parentAnchor,
        rootPath,
        allowRoot: false,
      );
      if (parentResolution.type != FileSystemEntityType.directory) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootNotDirectory,
          path: rootPath,
        );
      }
      final rootAnchor = await captureCanonicalDirectoryAnchor(rootPath);
      if (!p.equals(rootAnchor.rootPath, rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.symlinkComponent,
          path: rootPath,
        );
      }
      return rootAnchor;
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': error.path},
      );
    }
  }

  Future<AnchoredPathResolution> _projectPath(
    CanonicalPathAnchor anchor,
    String path,
  ) async {
    try {
      return await resolveAnchoredPath(anchor, path, allowRoot: false);
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': error.path},
      );
    }
  }

  Future<void> _createProjectDirectory(
    CanonicalPathAnchor anchor,
    String name,
  ) async {
    final path = p.join(anchor.rootPath, name);
    final target = await _projectPath(anchor, path);
    if (target.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.project.generated-file-exists',
        args: {'path': target.path},
      );
    }
    await Directory(target.path).create();
    final created = await _projectPath(anchor, target.path);
    if (created.type != FileSystemEntityType.directory) {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': created.path},
      );
    }
  }

  _ValidatedCreateRequest _validate(WritersideProjectCreateRequest request) {
    final parentDirectoryPath = request.parentDirectoryPath.trim();
    if (parentDirectoryPath.isEmpty) {
      throw const BusyMarkException(
        'writerside.project.parent-directory-required',
      );
    }
    final normalizedParentPath = normalizePath(parentDirectoryPath);
    final parentType = FileSystemEntity.typeSync(normalizedParentPath);
    if (parentType != FileSystemEntityType.directory) {
      throw BusyMarkException(
        'writerside.project.parent-directory-missing',
        args: {'path': normalizedParentPath},
      );
    }

    final projectName = request.projectName.trim();
    if (projectName.isEmpty) {
      throw const BusyMarkException('writerside.project.name-required');
    }

    final directoryName = request.directoryName.trim();
    if (directoryName.isEmpty) {
      throw const BusyMarkException('writerside.project.directory-required');
    }
    if (directoryName == '.' ||
        directoryName == '..' ||
        p.isAbsolute(directoryName) ||
        directoryName.contains('..') ||
        directoryName.contains('/') ||
        directoryName.contains(r'\')) {
      throw const BusyMarkException('writerside.project.directory-unsafe');
    }

    final instanceId = request.instanceId.trim();
    if (!isValidInstanceId(instanceId)) {
      throw const BusyMarkException('writerside.project.instance-id-invalid');
    }

    final topicTitle = request.topicTitle.trim();
    if (topicTitle.isEmpty) {
      throw const BusyMarkException('writerside.project.topic-title-required');
    }

    final generatedTopicSlug = slugForHeading(topicTitle);
    final topicFileName = request.topicFileName == null
        ? '${generatedTopicSlug.isEmpty ? 'getting-started' : generatedTopicSlug}.md'
        : request.topicFileName!.trim();
    if (topicFileName.isEmpty ||
        topicFileName == '.' ||
        topicFileName == '..' ||
        p.isAbsolute(topicFileName) ||
        topicFileName.contains('..') ||
        topicFileName.contains('/') ||
        topicFileName.contains(r'\') ||
        !topicFileName.endsWith('.md')) {
      throw const BusyMarkException('writerside.project.topic-file-invalid');
    }

    final instanceName = request.instanceName.trim().isEmpty
        ? projectName
        : request.instanceName.trim();
    final moduleName = request.moduleName?.trim().isNotEmpty == true
        ? request.moduleName!.trim()
        : projectName;

    return _ValidatedCreateRequest(
      parentDirectoryPath: normalizedParentPath,
      directoryName: directoryName,
      moduleName: moduleName,
      instanceName: instanceName,
      instanceId: instanceId,
      topicTitle: topicTitle,
      topicFileName: topicFileName,
    );
  }

  Future<bool> _isDirectoryEmpty(Directory directory) async {
    await for (final _ in directory.list()) {
      return false;
    }
    return true;
  }

  Future<void> _writeNewFile(
    CanonicalPathAnchor anchor,
    String path,
    String content,
  ) async {
    final target = await _projectPath(anchor, path);
    if (target.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.project.generated-file-exists',
        args: {'path': target.path},
      );
    }
    await File(target.path).create(exclusive: true);
    final created = await _projectPath(anchor, target.path);
    if (created.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': created.path},
      );
    }
    await File(created.path).writeAsString(content);
  }

  String _writersideConfig({
    required String moduleName,
    required String treeFileName,
  }) {
    final escapedModuleName = _xmlAttribute(moduleName);
    final escapedTreeFileName = _xmlAttribute(treeFileName);
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE ihp SYSTEM "https://resources.jetbrains.com/writerside/1.0/ihp.dtd">\n'
        '<ihp version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
        '     xsi:noNamespaceSchemaLocation="https://resources.jetbrains.com/writerside/1.0/writerside-cfg.xsd">\n'
        '  <module name="$escapedModuleName"/>\n'
        '  <topics dir="topics"/>\n'
        '  <images dir="images"/>\n'
        '  <build-config dir="cfg"/>\n'
        '  <instance src="$escapedTreeFileName"/>\n'
        '</ihp>\n';
  }

  String _writersideTree({
    required String instanceId,
    required String instanceName,
    required String topicFileName,
  }) {
    final escapedInstanceId = _xmlAttribute(instanceId);
    final escapedInstanceName = _xmlAttribute(instanceName);
    final escapedTopicFileName = _xmlAttribute(topicFileName);
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE instance-profile SYSTEM "https://resources.jetbrains.com/writerside/1.0/product-profile.dtd">\n'
        '<instance-profile id="$escapedInstanceId" name="$escapedInstanceName" start-page="$escapedTopicFileName">\n'
        '  <toc-element topic="$escapedTopicFileName"/>\n'
        '</instance-profile>\n';
  }

  String _startTopic({required String title}) {
    return '# ${_markdownHeadingText(title)}\n';
  }

  String _markdownHeadingText(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.replaceAllMapped(RegExp(r'[&<>%\[\]()!`*_{}#\\=:]'), (
      match,
    ) {
      return switch (match.group(0)!) {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '%' => '&#37;',
        '[' => '&#91;',
        ']' => '&#93;',
        '(' => '&#40;',
        ')' => '&#41;',
        '!' => '&#33;',
        '`' => '&#96;',
        '*' => '&#42;',
        '_' => '&#95;',
        '{' => '&#123;',
        '}' => '&#125;',
        '#' => '&#35;',
        '\\' => '&#92;',
        '=' => '&#61;',
        ':' => '&#58;',
        _ => match.group(0)!,
      };
    });
  }

  String _xmlAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _ValidatedCreateRequest {
  const _ValidatedCreateRequest({
    required this.parentDirectoryPath,
    required this.directoryName,
    required this.moduleName,
    required this.instanceName,
    required this.instanceId,
    required this.topicTitle,
    required this.topicFileName,
  });

  final String parentDirectoryPath;
  final String directoryName;
  final String moduleName;
  final String instanceName;
  final String instanceId;
  final String topicTitle;
  final String topicFileName;
}
