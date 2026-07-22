import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/path_utils.dart';
import 'writerside_model.dart';

enum WritersideTopicCreatePlacement { root, sibling, child }

/// Semantic identity of a TOC subtree captured when the user selects it.
///
/// Structural index paths can become stale when another writer inserts or
/// removes an entry. Mutations compare this snapshot with the element found at
/// the requested path before changing the tree.
class WritersideTocNodeIdentity {
  const WritersideTocNodeIdentity({
    required this.hidden,
    this.topicFileName,
    this.href,
    this.tocTitle,
    this.id,
    this.children = const [],
  });

  factory WritersideTocNodeIdentity.fromNode(TocNode node) {
    return WritersideTocNodeIdentity(
      topicFileName: node.topicFileName,
      href: node.href,
      tocTitle: node.tocTitle,
      id: node.id,
      hidden: node.hidden,
      children: [
        for (final child in node.children)
          WritersideTocNodeIdentity.fromNode(child),
      ],
    );
  }

  final String? topicFileName;
  final String? href;
  final String? tocTitle;
  final String? id;
  final bool hidden;
  final List<WritersideTocNodeIdentity> children;

  bool matches(XmlElement element) {
    if (element.name.local != 'toc-element' ||
        element.getAttribute('topic') != topicFileName ||
        element.getAttribute('href') != href ||
        element.getAttribute('toc-title') != tocTitle ||
        element.getAttribute('id') != id ||
        (element.getAttribute('hidden') == 'true') != hidden) {
      return false;
    }
    final elementChildren = element.childElements
        .where((child) => child.name.local == 'toc-element')
        .toList();
    if (elementChildren.length != children.length) {
      return false;
    }
    for (var index = 0; index < children.length; index += 1) {
      if (!children[index].matches(elementChildren[index])) {
        return false;
      }
    }
    return true;
  }
}

class WritersideTopicCreateRequest {
  const WritersideTopicCreateRequest({
    required this.title,
    required this.fileName,
    this.format = WritersideTopicFormat.markdown,
    this.placement = WritersideTopicCreatePlacement.root,
    this.referenceTopic,
    this.referenceTocPath,
    this.referenceTocIdentity,
  });

  final String title;
  final String fileName;
  final WritersideTopicFormat format;
  final WritersideTopicCreatePlacement placement;
  final String? referenceTopic;

  /// Zero-based indexes among the `toc-element` children at each level.
  ///
  /// When provided, this identifies the exact reference node for a sibling or
  /// child insertion. It takes precedence over [referenceTopic], which remains
  /// available for compatibility with callers that only know a topic filename.
  final List<int>? referenceTocPath;

  /// Expected node at [referenceTocPath], used to reject stale UI paths.
  final WritersideTocNodeIdentity? referenceTocIdentity;
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
  const WritersideTopicCreator({
    Future<void> Function(String treePath)? beforeTreePublish,
  }) : _beforeTreePublish = beforeTreePublish;

  /// Test seam invoked after the replacement tree is staged but immediately
  /// before its final compare-and-publish check.
  ///
  /// Production callers should leave this unset. The source comparison still
  /// runs after the callback, so using the seam cannot bypass the disk-change
  /// guard.
  final Future<void> Function(String treePath)? _beforeTreePublish;

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
    final topicSource = _topicSource(request.format, topicId, title);
    var topicCreated = false;
    try {
      await _writeNewFile(rootAnchor, topicPath, topicSource);
      topicCreated = true;
      await _replaceTreeAtomically(
        rootAnchor,
        treePath,
        updatedTree,
        expectedCurrentSource: treeSource,
      );
    } on Object {
      if (topicCreated) {
        await _deleteCreatedFileBestEffort(rootAnchor, topicPath, topicSource);
      }
      rethrow;
    }

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
    if (request.placement == WritersideTopicCreatePlacement.root) {
      root.children.add(element);
      return _treeXml(document);
    }

    final referencePath = request.referenceTocPath;
    if (referencePath != null) {
      final referenceElement = _tocElementAtPath(root, referencePath);
      if (referenceElement == null ||
          !(request.referenceTocIdentity?.matches(referenceElement) ?? true)) {
        throw BusyMarkException(
          'writerside.topic.reference-missing',
          args: {'topic': _tocPathLabel(referencePath)},
        );
      }
      switch (request.placement) {
        case WritersideTopicCreatePlacement.child:
          referenceElement.children.add(element);
        case WritersideTopicCreatePlacement.sibling:
          _insertAfterElement(referenceElement, element);
        case WritersideTopicCreatePlacement.root:
          break;
      }
      return _treeXml(document);
    }

    final referenceTopic = request.referenceTopic?.trim();
    if (referenceTopic == null || referenceTopic.isEmpty) {
      throw const BusyMarkException(
        'writerside.topic.reference-missing',
        args: {'topic': ''},
      );
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

  XmlElement? _tocElementAtPath(XmlElement root, List<int> path) {
    if (path.isEmpty || path.any((index) => index < 0)) {
      return null;
    }
    var parent = root;
    for (var depth = 0; depth < path.length; depth += 1) {
      final children = parent.childElements
          .where((element) => element.name.local == 'toc-element')
          .toList();
      final index = path[depth];
      if (index >= children.length) {
        return null;
      }
      parent = children[index];
    }
    return parent;
  }

  void _insertAfterElement(XmlElement reference, XmlElement element) {
    final parent = reference.parent;
    if (parent is! XmlElement) {
      throw const BusyMarkException(
        'writerside.topic.reference-missing',
        args: {'topic': ''},
      );
    }
    final index = parent.children.indexOf(reference);
    if (index < 0) {
      throw const BusyMarkException(
        'writerside.topic.reference-missing',
        args: {'topic': ''},
      );
    }
    parent.children.insert(index + 1, element);
  }

  String _tocPathLabel(List<int> path) => path.join('/');

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
    final file = File(target.path);
    var createdByThisOperation = false;
    try {
      await file.create(exclusive: true);
      createdByThisOperation = true;
      final created = await _topicTargetPath(anchor, target.path);
      if (created.type != FileSystemEntityType.file) {
        throw BusyMarkException(
          'writerside.topic.file-exists',
          args: {'path': created.path},
        );
      }
      await File(created.path).writeAsString(content, flush: true);
    } on Object {
      if (createdByThisOperation) {
        await _deleteCreatedFileBestEffort(anchor, target.path, content);
      }
      rethrow;
    }
  }

  Future<void> _replaceTreeAtomically(
    CanonicalPathAnchor anchor,
    String path,
    String source, {
    required String expectedCurrentSource,
  }) async {
    final tree = await _treePath(anchor, path);
    await _ensureTreeUnchanged(tree, expectedCurrentSource);
    final targetStat = await File(tree.path).stat();
    final temporary = await _newTreeTemporaryFile(anchor, tree.path);
    try {
      await temporary.writeAsString(source, flush: true);
      await _copyFileMode(targetStat, temporary);
      await _beforeTreePublish?.call(tree.path);

      final publishTarget = await _treePath(anchor, path);
      await _ensureTreeUnchanged(publishTarget, expectedCurrentSource);
      await temporary.rename(publishTarget.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<void> _ensureTreeUnchanged(
    AnchoredPathResolution tree,
    String expectedSource,
  ) async {
    if (tree.type != FileSystemEntityType.file ||
        await File(tree.path).readAsString() != expectedSource) {
      throw BusyMarkException(
        'writerside.topic.tree-changed',
        args: {'path': tree.path},
      );
    }
  }

  Future<File> _newTreeTemporaryFile(
    CanonicalPathAnchor anchor,
    String targetPath,
  ) async {
    for (var attempt = 0; attempt < 100; attempt += 1) {
      final name =
          '.${p.basename(targetPath)}.busymark-topic-create-'
          '$pid-${DateTime.now().microsecondsSinceEpoch}-$attempt';
      final candidatePath = p.join(p.dirname(targetPath), name);
      final resolution = await _treePath(anchor, candidatePath);
      if (resolution.type != FileSystemEntityType.notFound) {
        continue;
      }
      try {
        return await File(resolution.path).create(exclusive: true);
      } on FileSystemException {
        continue;
      }
    }
    throw BusyMarkException(
      'writerside.topic.temporary-file-failed',
      args: {'path': targetPath},
    );
  }

  Future<void> _copyFileMode(FileStat sourceStat, File target) async {
    if (Platform.isWindows) {
      return;
    }
    final mode = (sourceStat.mode & 0xfff).toRadixString(8);
    final result = await Process.run('chmod', [mode, target.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Failed to apply file mode $mode: ${result.stderr}',
        target.path,
      );
    }
  }

  Future<void> _deleteCreatedFileBestEffort(
    CanonicalPathAnchor anchor,
    String path,
    String expectedContent,
  ) async {
    try {
      final resolution = await _topicTargetPath(anchor, path);
      if (resolution.type == FileSystemEntityType.file &&
          await File(resolution.path).readAsString() == expectedContent) {
        await File(resolution.path).delete();
      }
    } on Object {
      // Best effort cleanup after a failed multi-file publication. Never
      // delete a path whose anchored identity and contents were not verified.
    }
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
