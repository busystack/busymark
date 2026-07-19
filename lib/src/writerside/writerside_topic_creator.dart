import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/path_utils.dart';
import 'writerside_model.dart';

enum WritersideTopicCreatePlacement { root, sibling, child }

class WritersideTopicCreateRequest {
  const WritersideTopicCreateRequest({
    required this.title,
    required this.fileName,
    this.format = WritersideTopicFormat.markdown,
    this.placement = WritersideTopicCreatePlacement.root,
    this.referenceTopic,
  });

  final String title;
  final String fileName;
  final WritersideTopicFormat format;
  final WritersideTopicCreatePlacement placement;
  final String? referenceTopic;
}

class WritersideTopicCreateTarget {
  const WritersideTopicCreateTarget({
    required this.rootPath,
    required this.treePath,
    required this.topicsRootDir,
    required this.existingTopicIds,
  });

  final String rootPath;
  final String treePath;
  final String topicsRootDir;
  final Set<String> existingTopicIds;
}

class WritersideTopicCreateResult {
  const WritersideTopicCreateResult({
    required this.topicPath,
    required this.treePath,
    required this.topicFileName,
  });

  final String topicPath;
  final String treePath;
  final String topicFileName;
}

class WritersideTopicCreator {
  const WritersideTopicCreator();

  Future<WritersideTopicCreateResult> create(
    WritersideTopicCreateTarget target,
    WritersideTopicCreateRequest request,
  ) async {
    final rootPath = normalizePath(target.rootPath);
    final CanonicalPathAnchor rootAnchor;
    try {
      rootAnchor = await captureCanonicalDirectoryAnchor(rootPath);
      if (!p.equals(rootAnchor.requestedRootPath, rootAnchor.rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootReplacement,
          path: rootAnchor.requestedRootPath,
        );
      }
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic.module-root-missing',
        args: {'path': error.path},
      );
    }
    final treeResolution = await _treePath(rootAnchor, target.treePath);
    if (treeResolution.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': treeResolution.path},
      );
    }
    final treePath = treeResolution.path;
    final topicsRootDir = _safeRelativeDirectory(target.topicsRootDir);
    final topicsRootResolution = await _topicsRootPath(
      rootAnchor,
      p.join(rootAnchor.rootPath, topicsRootDir),
    );
    if (topicsRootResolution.type != FileSystemEntityType.directory &&
        topicsRootResolution.type != FileSystemEntityType.notFound) {
      throw const BusyMarkException('writerside.topic.topics-root-unsafe');
    }
    final topicsRootPath = topicsRootResolution.path;
    final topicFileName = _topicFileName(request.fileName, request.format);
    final topicId = p.basenameWithoutExtension(topicFileName);
    if (target.existingTopicIds.contains(topicId)) {
      throw BusyMarkException(
        'writerside.topic.id-exists',
        args: {'topicId': topicId},
      );
    }
    final title = request.title.trim();
    if (title.isEmpty) {
      throw const BusyMarkException('writerside.topic.title-required');
    }

    final topicResolution = await _topicTargetPath(
      rootAnchor,
      p.join(topicsRootPath, topicFileName),
      allowMissingAncestors: true,
    );
    final topicPath = topicResolution.path;
    if (topicResolution.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.topic.file-exists',
        args: {'path': topicPath},
      );
    }

    final treeSource = await File(treePath).readAsString();
    final updatedTree = _updatedTree(
      treePath: treePath,
      source: treeSource,
      topicFileName: topicFileName,
      request: request,
    );

    final checkedTopicsRoot = await _topicsRootPath(rootAnchor, topicsRootPath);
    if (checkedTopicsRoot.type == FileSystemEntityType.notFound) {
      await Directory(checkedTopicsRoot.path).create(recursive: true);
    } else if (checkedTopicsRoot.type != FileSystemEntityType.directory) {
      throw const BusyMarkException('writerside.topic.topics-root-unsafe');
    }
    final createdTopicsRoot = await _topicsRootPath(rootAnchor, topicsRootPath);
    if (createdTopicsRoot.type != FileSystemEntityType.directory) {
      throw const BusyMarkException('writerside.topic.topics-root-unsafe');
    }
    await _writeNewFile(
      rootAnchor,
      topicPath,
      _topicSource(request.format, topicId, title),
    );
    final checkedTree = await _treePath(rootAnchor, treePath);
    if (checkedTree.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': checkedTree.path},
      );
    }
    await File(checkedTree.path).writeAsString(updatedTree);

    return WritersideTopicCreateResult(
      topicPath: topicPath,
      treePath: treePath,
      topicFileName: topicFileName,
    );
  }

  Future<AnchoredPathResolution> _treePath(
    CanonicalPathAnchor anchor,
    String path,
  ) async {
    try {
      return await resolveAnchoredPath(
        anchor,
        normalizePath(path),
        allowRoot: false,
      );
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': error.path},
      );
    }
  }

  Future<AnchoredPathResolution> _topicsRootPath(
    CanonicalPathAnchor anchor,
    String path,
  ) async {
    try {
      return await resolveAnchoredPath(
        anchor,
        path,
        allowRoot: false,
        allowMissingAncestors: true,
      );
    } on AnchoredPathViolation {
      throw const BusyMarkException('writerside.topic.topics-root-unsafe');
    }
  }

  Future<AnchoredPathResolution> _topicTargetPath(
    CanonicalPathAnchor anchor,
    String path, {
    bool allowMissingAncestors = false,
  }) async {
    try {
      return await resolveAnchoredPath(
        anchor,
        path,
        allowRoot: false,
        allowMissingAncestors: allowMissingAncestors,
      );
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic.file-exists',
        args: {'path': error.path},
      );
    }
  }

  String _updatedTree({
    required String treePath,
    required String source,
    required String topicFileName,
    required WritersideTopicCreateRequest request,
  }) {
    final document = XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'instance-profile') {
      throw FormatException('.tree root must be <instance-profile>.', treePath);
    }
    final element = XmlElement(XmlName.parts('toc-element'), [
      XmlAttribute(XmlName.parts('topic'), topicFileName),
    ]);
    final referenceTopic = request.referenceTopic?.trim();
    if (request.placement == WritersideTopicCreatePlacement.root ||
        referenceTopic == null ||
        referenceTopic.isEmpty) {
      root.children.add(element);
      return _treeXml(document);
    }
    final inserted = switch (request.placement) {
      WritersideTopicCreatePlacement.child => _appendToTopic(
        root,
        referenceTopic,
        element,
      ),
      WritersideTopicCreatePlacement.sibling => _insertAfterTopic(
        root,
        referenceTopic,
        element,
      ),
      WritersideTopicCreatePlacement.root => true,
    };
    if (!inserted) {
      throw BusyMarkException(
        'writerside.topic.reference-missing',
        args: {'topic': referenceTopic},
      );
    }
    return _treeXml(document);
  }

  bool _appendToTopic(
    XmlElement current,
    String referenceTopic,
    XmlElement element,
  ) {
    for (final child in current.childElements) {
      if (child.name.local == 'toc-element' &&
          child.getAttribute('topic') == referenceTopic) {
        child.children.add(element);
        return true;
      }
      if (_appendToTopic(child, referenceTopic, element)) {
        return true;
      }
    }
    return false;
  }

  bool _insertAfterTopic(
    XmlElement current,
    String referenceTopic,
    XmlElement element,
  ) {
    for (var index = 0; index < current.children.length; index++) {
      final child = current.children[index];
      if (child is XmlElement) {
        if (child.name.local == 'toc-element' &&
            child.getAttribute('topic') == referenceTopic) {
          current.children.insert(index + 1, element);
          return true;
        }
        if (_insertAfterTopic(child, referenceTopic, element)) {
          return true;
        }
      }
    }
    return false;
  }

  String _treeXml(XmlDocument document) {
    return '${document.toXmlString(pretty: true, indent: '  ')}\n';
  }

  Future<void> _writeNewFile(
    CanonicalPathAnchor anchor,
    String path,
    String content,
  ) async {
    final target = await _topicTargetPath(anchor, path);
    if (target.type != FileSystemEntityType.notFound) {
      throw BusyMarkException(
        'writerside.topic.file-exists',
        args: {'path': target.path},
      );
    }
    await File(target.path).create(exclusive: true);
    final created = await _topicTargetPath(anchor, target.path);
    if (created.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic.file-exists',
        args: {'path': created.path},
      );
    }
    await File(created.path).writeAsString(content);
  }

  String _safeRelativeDirectory(String value) {
    final directory = value.trim();
    if (directory.isEmpty ||
        directory == '.' ||
        directory == '..' ||
        p.isAbsolute(directory) ||
        directory.split(RegExp(r'[/\\]+')).contains('..')) {
      throw const BusyMarkException('writerside.topic.topics-root-unsafe');
    }
    return p.normalize(directory).replaceAll(r'\', '/');
  }

  String _topicFileName(String value, WritersideTopicFormat format) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed == '.' ||
        trimmed == '..' ||
        p.isAbsolute(trimmed) ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed.contains('..')) {
      throw const BusyMarkException('writerside.topic.file-name-unsafe');
    }
    final expectedExtension = switch (format) {
      WritersideTopicFormat.markdown => '.md',
      WritersideTopicFormat.xml => '.topic',
    };
    final extension = p.extension(trimmed).toLowerCase();
    final fileName = extension.isEmpty ? '$trimmed$expectedExtension' : trimmed;
    if (p.extension(fileName).toLowerCase() != expectedExtension) {
      throw BusyMarkException(
        'writerside.topic.file-extension-mismatch',
        args: {'extension': expectedExtension},
      );
    }
    final id = p.basenameWithoutExtension(fileName);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw const BusyMarkException('writerside.topic.file-name-invalid');
    }
    return fileName;
  }

  String _topicSource(WritersideTopicFormat format, String id, String title) {
    return switch (format) {
      WritersideTopicFormat.markdown => '# ${_markdownHeadingText(title)}\n\n',
      WritersideTopicFormat.xml =>
        '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<topic xsi:noNamespaceSchemaLocation="https://resources.jetbrains.com/writerside/1.0/topic.v2.xsd" '
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
            'title="${_xmlAttribute(title)}" id="${_xmlAttribute(id)}">\n'
            '  <p>Start writing here.</p>\n'
            '</topic>\n',
    };
  }

  String _markdownHeadingText(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
