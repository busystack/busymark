import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/busymark_exception.dart';
import '../core/path_utils.dart';

class WritersideProjectCreateRequest {
  const WritersideProjectCreateRequest({
    required this.parentDirectoryPath,
    required this.projectName,
    required this.directoryName,
    required this.instanceName,
    required this.topicTitle,
    this.moduleName,
    this.instanceId = 'user-guide',
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
  ) async {
    final validated = _validate(request);
    final rootPath = normalizePath(
      p.join(validated.parentDirectoryPath, validated.directoryName),
    );
    final rootDirectory = Directory(rootPath);
    final rootType = await FileSystemEntity.type(rootPath);
    if (rootType == FileSystemEntityType.directory) {
      if (!await _isDirectoryEmpty(rootDirectory)) {
        throw BusyMarkException(
          'writerside.project.target-directory-not-empty',
          args: {'path': rootPath},
        );
      }
    } else if (rootType == FileSystemEntityType.notFound) {
      await rootDirectory.create();
    } else {
      throw BusyMarkException(
        'writerside.project.target-path-not-directory',
        args: {'path': rootPath},
      );
    }

    final treeFileName = '${validated.instanceId}.tree';
    final configFile = File(p.join(rootPath, 'writerside.cfg'));
    final treeFile = File(p.join(rootPath, treeFileName));
    final topicFile = File(p.join(rootPath, 'topics', validated.topicFileName));
    for (final file in [configFile, treeFile, topicFile]) {
      if (await file.exists()) {
        throw BusyMarkException(
          'writerside.project.generated-file-exists',
          args: {'path': file.path},
        );
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
      configPath: configFile.path,
      treePath: treeFile.path,
      startTopicPath: topicFile.path,
    );
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

    final topicFileName = request.topicFileName.trim();
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

    final topicTitle = request.topicTitle.trim();
    if (topicTitle.isEmpty) {
      throw const BusyMarkException('writerside.project.topic-title-required');
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
    return '# ${_markdownHeadingText(title)}\n\n'
        'Start writing your documentation here.\n\n'
        'This Writerside-compatible starter project was created by BusyMark.\n';
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
