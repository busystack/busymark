import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

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
    if (!Directory(rootPath).existsSync()) {
      throw BusyMarkException(
        'writerside.topic.module-root-missing',
        args: {'path': rootPath},
      );
    }
    final treePath = normalizePath(target.treePath);
    final treeFile = File(treePath);
    if (!treeFile.existsSync()) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': treePath},
      );
    }
    final topicsRootDir = _safeRelativeDirectory(target.topicsRootDir);
    final topicsRootPath = normalizePath(p.join(rootPath, topicsRootDir));
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

    final topicPath = normalizePath(p.join(topicsRootPath, topicFileName));
    final topicFile = File(topicPath);
    if (topicFile.existsSync()) {
      throw BusyMarkException(
        'writerside.topic.file-exists',
        args: {'path': topicPath},
      );
    }

    final treeSource = await treeFile.readAsString();
    final updatedTree = _updatedTree(
      treePath: treePath,
      source: treeSource,
      topicFileName: topicFileName,
      request: request,
    );

    await Directory(topicsRootPath).create(recursive: true);
    await _writeNewFile(
      topicFile,
      _topicSource(request.format, topicId, title),
    );
    await treeFile.writeAsString(updatedTree);

    return WritersideTopicCreateResult(
      topicPath: topicPath,
      treePath: treePath,
      topicFileName: topicFileName,
    );
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

  Future<void> _writeNewFile(File file, String content) async {
    final created = await file.create(exclusive: true);
    await created.writeAsString(content);
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
