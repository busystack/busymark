import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/path_utils.dart';
import 'writerside_topic_creator.dart';

/// Identifies the Writerside instance tree that a TOC operation may mutate.
class WritersideTocEditTarget {
  const WritersideTocEditTarget({
    required this.rootPath,
    required this.treePath,
  });

  final String rootPath;
  final String treePath;
}

/// Moves one complete `toc-element` subtree.
///
/// Paths contain zero-based indexes among `toc-element` children only. For
/// example, `[1, 0]` identifies the first child of the second root entry.
class WritersideTocMoveRequest {
  const WritersideTocMoveRequest({
    required this.sourcePath,
    required this.placement,
    this.referencePath,
    this.sourceIdentity,
    this.referenceIdentity,
  });

  final List<int> sourcePath;
  final WritersideTopicCreatePlacement placement;

  /// The exact sibling or parent entry used for non-root placement.
  ///
  /// This must be omitted for [WritersideTopicCreatePlacement.root] and is
  /// required for sibling and child placement.
  final List<int>? referencePath;
  final WritersideTocNodeIdentity? sourceIdentity;
  final WritersideTocNodeIdentity? referenceIdentity;
}

class WritersideTocMutationResult {
  const WritersideTocMutationResult({required this.treePath, this.entryPath});

  final String treePath;

  /// The moved entry's structural path after a move, or `null` after removal.
  final List<int>? entryPath;
}

/// Performs structural Writerside TOC mutations inside a guarded module root.
class WritersideTocEditor {
  const WritersideTocEditor({
    Future<void> Function(String treePath)? beforeTreePublish,
  }) : _beforeTreePublish = beforeTreePublish;

  /// Test seam invoked after an updated tree is staged but before publication.
  ///
  /// Production callers should leave this unset. The final source comparison
  /// still runs after the callback, so it can deterministically exercise a
  /// concurrent writer without weakening the publication guard.
  final Future<void> Function(String treePath)? _beforeTreePublish;

  Future<WritersideTocMutationResult> moveSubtree(
    WritersideTocEditTarget target,
    WritersideTocMoveRequest request,
  ) async {
    _validatePath(request.sourcePath, role: 'source');
    final referencePath = request.referencePath;
    if (request.placement == WritersideTopicCreatePlacement.root) {
      if (referencePath != null) {
        throw _invalidPath(referencePath, role: 'destination');
      }
    } else {
      if (referencePath == null) {
        throw const BusyMarkException('writerside.toc.destination-required');
      }
      _validatePath(referencePath, role: 'destination');
      if (_isSameOrDescendant(request.sourcePath, referencePath)) {
        throw BusyMarkException(
          'writerside.toc.move-invalid-target',
          args: {
            'source': _pathLabel(request.sourcePath),
            'destination': _pathLabel(referencePath),
          },
        );
      }
    }

    final session = await _load(target);
    final source = _elementAtPath(
      session.root,
      request.sourcePath,
      role: 'source',
    );
    if (!(request.sourceIdentity?.matches(source) ?? true)) {
      throw _invalidPath(request.sourcePath, role: 'source');
    }
    final reference = referencePath == null
        ? null
        : _elementAtPath(session.root, referencePath, role: 'destination');
    if (reference != null &&
        !(request.referenceIdentity?.matches(reference) ?? true)) {
      throw _invalidPath(referencePath!, role: 'destination');
    }
    final sourceParent = source.parent;
    if (sourceParent is! XmlElement || !sourceParent.children.remove(source)) {
      throw _invalidPath(request.sourcePath, role: 'source');
    }

    switch (request.placement) {
      case WritersideTopicCreatePlacement.root:
        session.root.children.add(source);
      case WritersideTopicCreatePlacement.sibling:
        _insertAfter(reference!, source);
      case WritersideTopicCreatePlacement.child:
        reference!.children.add(source);
    }

    final movedPath = _pathOfElement(session.root, source);
    if (movedPath == null) {
      throw const BusyMarkException('writerside.toc.move-invalid-target');
    }
    await _write(session);
    return WritersideTocMutationResult(
      treePath: session.treePath,
      entryPath: movedPath,
    );
  }

  /// Removes one TOC entry while retaining its direct `toc-element` children.
  ///
  /// Promoted children are inserted at the removed entry's position and keep
  /// their original order and complete descendant subtrees.
  Future<WritersideTocMutationResult> removeEntry(
    WritersideTocEditTarget target,
    List<int> entryPath, {
    WritersideTocNodeIdentity? expectedIdentity,
  }) async {
    _validatePath(entryPath, role: 'source');
    final session = await _load(target);
    final entry = _elementAtPath(session.root, entryPath, role: 'source');
    if (!(expectedIdentity?.matches(entry) ?? true)) {
      throw _invalidPath(entryPath, role: 'source');
    }
    final parent = entry.parent;
    if (parent is! XmlElement) {
      throw _invalidPath(entryPath, role: 'source');
    }
    final rawIndex = parent.children.indexOf(entry);
    if (rawIndex < 0) {
      throw _invalidPath(entryPath, role: 'source');
    }
    final promotedChildren = entry.childElements.where(_isTocElement).toList();
    for (final child in promotedChildren) {
      entry.children.remove(child);
    }
    parent.children.removeAt(rawIndex);
    parent.children.insertAll(rawIndex, promotedChildren);

    await _write(session);
    return WritersideTocMutationResult(treePath: session.treePath);
  }

  Future<_TocEditSession> _load(WritersideTocEditTarget target) async {
    final rootPath = normalizePath(target.rootPath);
    final CanonicalPathAnchor anchor;
    try {
      anchor = await captureCanonicalDirectoryAnchor(rootPath);
      if (!p.equals(anchor.requestedRootPath, anchor.rootPath)) {
        throw AnchoredPathViolation(
          reason: AnchoredPathViolationReason.rootReplacement,
          path: anchor.requestedRootPath,
        );
      }
    } on AnchoredPathViolation catch (error) {
      throw BusyMarkException(
        'writerside.topic.module-root-missing',
        args: {'path': error.path},
      );
    }
    final tree = await _treePath(anchor, target.treePath);
    if (tree.type != FileSystemEntityType.file) {
      throw BusyMarkException(
        'writerside.topic.tree-file-missing',
        args: {'path': tree.path},
      );
    }
    final source = await File(tree.path).readAsString();
    final document = XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'instance-profile') {
      throw FormatException(
        '.tree root must be <instance-profile>.',
        tree.path,
      );
    }
    return _TocEditSession(
      anchor: anchor,
      treePath: tree.path,
      originalSource: source,
      document: document,
      root: root,
    );
  }

  Future<void> _write(_TocEditSession session) async {
    final checkedTree = await _treePath(session.anchor, session.treePath);
    await _ensureTreeUnchanged(session, checkedTree);
    final targetStat = await File(checkedTree.path).stat();
    final temporary = await _newTemporaryFile(session.anchor, checkedTree.path);
    try {
      await temporary.writeAsString(
        '${session.document.toXmlString(pretty: true, indent: '  ')}\n',
        flush: true,
      );
      await _copyFileMode(targetStat, temporary);
      await _beforeTreePublish?.call(checkedTree.path);

      final publishTarget = await _treePath(session.anchor, session.treePath);
      await _ensureTreeUnchanged(session, publishTarget);
      await temporary.rename(publishTarget.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<void> _ensureTreeUnchanged(
    _TocEditSession session,
    AnchoredPathResolution tree,
  ) async {
    if (tree.type != FileSystemEntityType.file ||
        await File(tree.path).readAsString() != session.originalSource) {
      throw BusyMarkException(
        'writerside.toc.tree-changed',
        args: {'path': tree.path},
      );
    }
  }

  Future<File> _newTemporaryFile(
    CanonicalPathAnchor anchor,
    String targetPath,
  ) async {
    for (var attempt = 0; attempt < 100; attempt += 1) {
      final name =
          '.${p.basename(targetPath)}.busymark-toc-edit-'
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
      'writerside.toc.temporary-file-failed',
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

  XmlElement _elementAtPath(
    XmlElement root,
    List<int> path, {
    required String role,
  }) {
    var parent = root;
    for (var depth = 0; depth < path.length; depth += 1) {
      final children = parent.childElements.where(_isTocElement).toList();
      final index = path[depth];
      if (index >= children.length) {
        throw _invalidPath(path, role: role);
      }
      parent = children[index];
    }
    return parent;
  }

  void _insertAfter(XmlElement reference, XmlElement entry) {
    final parent = reference.parent;
    if (parent is! XmlElement) {
      throw const BusyMarkException('writerside.toc.move-invalid-target');
    }
    final index = parent.children.indexOf(reference);
    if (index < 0) {
      throw const BusyMarkException('writerside.toc.move-invalid-target');
    }
    parent.children.insert(index + 1, entry);
  }

  List<int>? _pathOfElement(XmlElement root, XmlElement target) {
    List<int>? visit(XmlElement parent, List<int> parentPath) {
      final children = parent.childElements.where(_isTocElement).toList();
      for (var index = 0; index < children.length; index += 1) {
        final child = children[index];
        final path = [...parentPath, index];
        if (identical(child, target)) {
          return path;
        }
        final nested = visit(child, path);
        if (nested != null) {
          return nested;
        }
      }
      return null;
    }

    return visit(root, const []);
  }

  void _validatePath(List<int> path, {required String role}) {
    if (path.isEmpty || path.any((index) => index < 0)) {
      throw _invalidPath(path, role: role);
    }
  }

  BusyMarkException _invalidPath(List<int> path, {required String role}) {
    return BusyMarkException(
      'writerside.toc.path-invalid',
      args: {'path': _pathLabel(path), 'role': role},
    );
  }

  bool _isSameOrDescendant(List<int> source, List<int> destination) {
    if (destination.length < source.length) {
      return false;
    }
    for (var index = 0; index < source.length; index += 1) {
      if (source[index] != destination[index]) {
        return false;
      }
    }
    return true;
  }

  static bool _isTocElement(XmlElement element) =>
      element.name.local == 'toc-element';

  static String _pathLabel(List<int> path) => path.join('/');
}

class _TocEditSession {
  const _TocEditSession({
    required this.anchor,
    required this.treePath,
    required this.originalSource,
    required this.document,
    required this.root,
  });

  final CanonicalPathAnchor anchor;
  final String treePath;
  final String originalSource;
  final XmlDocument document;
  final XmlElement root;
}
