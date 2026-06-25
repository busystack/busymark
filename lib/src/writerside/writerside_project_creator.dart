import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/path_utils.dart';

class WritersideProjectCreateRequest {
  const WritersideProjectCreateRequest({
    required this.parentDirectoryPath,
    required this.projectName,
    required this.directoryName,
    this.moduleName,
    this.instanceName = 'User Guide',
    this.instanceId = 'user-guide',
    this.topicTitle = 'Getting started',
    this.topicFileName = 'getting-started.md',
  });

  final String parentDirectoryPath;
  final String projectName;
  final String directoryName;
  final String? moduleName;
  final String instanceName;
  final String instanceId;
  final String topicTitle;
  final String topicFileName;
}

class WritersideProjectCreateResult {
  const WritersideProjectCreateResult({
    required this.rootPath,
    required this.startTopicPath,
  });

  final String rootPath;
  final String startTopicPath;
}

class WritersideProjectCreator {
  const WritersideProjectCreator();

  static final _instanceIdPattern = RegExp(r'^[a-z][a-z0-9_-]*$');

  Future<WritersideProjectCreateResult> create(
    WritersideProjectCreateRequest request,
  ) async {
    final validated = _validate(request);
    final rootPath = normalizePath(
      p.join(validated.parentDirectoryPath, validated.directoryName),
    );
    final rootDirectory = Directory(rootPath);
    final rootType = await FileSystemEntity.type(rootPath);
    if (rootType == FileSystemEntityType.directory) {
      if (!await _isDirectoryEmpty(rootDirectory)) {
        throw FileSystemException(
          'Target directory already exists and is not empty',
          rootPath,
        );
      }
    } else if (rootType == FileSystemEntityType.notFound) {
      await rootDirectory.create();
    } else {
      throw FileSystemException(
        'Target path already exists and is not a directory',
        rootPath,
      );
    }

    final treeFileName = '${validated.instanceId}.tree';
    final configFile = File(p.join(rootPath, 'writerside.cfg'));
    final treeFile = File(p.join(rootPath, treeFileName));
    final topicFile = File(p.join(rootPath, 'topics', validated.topicFileName));
    for (final file in [configFile, treeFile, topicFile]) {
      if (await file.exists()) {
        throw FileSystemException('Generated file already exists', file.path);
      }
    }

    await Directory(p.join(rootPath, 'topics')).create();
    await Directory(p.join(rootPath, 'images')).create();
    await Directory(p.join(rootPath, 'cfg')).create();

    await _writeNewFile(
      configFile,
      _writersideConfig(
        moduleName: validated.moduleName,
        treeFileName: treeFileName,
      ),
    );
    await _writeNewFile(
      treeFile,
      _writersideTree(
        instanceId: validated.instanceId,
        instanceName: validated.instanceName,
        topicFileName: validated.topicFileName,
      ),
    );
    await _writeNewFile(topicFile, _startTopic(title: validated.topicTitle));

    return WritersideProjectCreateResult(
      rootPath: rootPath,
      startTopicPath: topicFile.path,
    );
  }

  _ValidatedCreateRequest _validate(WritersideProjectCreateRequest request) {
    final parentDirectoryPath = request.parentDirectoryPath.trim();
    if (parentDirectoryPath.isEmpty) {
      throw ArgumentError.value(
        request.parentDirectoryPath,
        'parentDirectoryPath',
        'Parent directory is required.',
      );
    }
    final normalizedParentPath = normalizePath(parentDirectoryPath);
    final parentType = FileSystemEntity.typeSync(normalizedParentPath);
    if (parentType != FileSystemEntityType.directory) {
      throw FileSystemException(
        'Parent directory does not exist',
        normalizedParentPath,
      );
    }

    final projectName = request.projectName.trim();
    if (projectName.isEmpty) {
      throw ArgumentError.value(
        request.projectName,
        'projectName',
        'Project name is required.',
      );
    }

    final directoryName = request.directoryName.trim();
    if (directoryName.isEmpty) {
      throw ArgumentError.value(
        request.directoryName,
        'directoryName',
        'Directory name is required.',
      );
    }
    if (directoryName == '.' ||
        directoryName == '..' ||
        directoryName.contains('..') ||
        directoryName.contains('/') ||
        directoryName.contains(r'\')) {
      throw ArgumentError.value(
        request.directoryName,
        'directoryName',
        'Directory name must be a single safe path segment.',
      );
    }

    final instanceId = request.instanceId.trim();
    if (!_instanceIdPattern.hasMatch(instanceId)) {
      throw ArgumentError.value(
        request.instanceId,
        'instanceId',
        'Instance ID must start with a lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens.',
      );
    }

    final topicFileName = request.topicFileName.trim();
    if (topicFileName.isEmpty ||
        topicFileName.contains('/') ||
        topicFileName.contains(r'\') ||
        !topicFileName.endsWith('.md')) {
      throw ArgumentError.value(
        request.topicFileName,
        'topicFileName',
        'Topic file name must be a Markdown file name without path separators.',
      );
    }

    final topicTitle = request.topicTitle.trim();
    if (topicTitle.isEmpty) {
      throw ArgumentError.value(
        request.topicTitle,
        'topicTitle',
        'Topic title is required.',
      );
    }

    final instanceName = request.instanceName.trim().isEmpty
        ? 'User Guide'
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

  Future<void> _writeNewFile(File file, String content) async {
    final created = await file.create(exclusive: true);
    await created.writeAsString(content);
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
    return '# $title\n\n'
        'Start writing your documentation here.\n\n'
        'This Writerside-compatible starter project was created by BusyMark.\n';
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
