import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/anchored_path_guard.dart';
import '../core/atomic_file_writer.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_service.dart';
import '../workspace/text_format_metadata.dart';
import 'markdown_references.dart';

class MarkdownDestinationEdit {
  const MarkdownDestinationEdit(this.start, this.end, this.before, this.after);
  final int start, end;
  final String before, after;
}

class MarkdownMoveFile {
  MarkdownMoveFile(this.path, this.load, List<MarkdownDestinationEdit> edits)
    : edits = List.unmodifiable(edits);
  final String path;
  final WorkspaceFileLoad load;
  final List<MarkdownDestinationEdit> edits;
  String get result {
    var text = load.text;
    for (final edit in edits.reversed) {
      text = text.replaceRange(edit.start, edit.end, edit.after);
    }
    return text;
  }
}

class MarkdownMovePlan {
  MarkdownMovePlan({
    required this.workspaceId,
    required this.root,
    required this.source,
    required this.destination,
    required this.anchor,
    required Map<String, String> mapping,
    required Map<String, WorkspaceFileSnapshot> snapshots,
    required Map<String, FileStat> identities,
    required List<String> inventory,
    required List<MarkdownMoveFile> files,
  }) : mapping = Map.unmodifiable(mapping),
       snapshots = Map.unmodifiable(snapshots),
       identities = Map.unmodifiable(identities),
       inventory = List.unmodifiable(inventory),
       files = List.unmodifiable(files);
  final String workspaceId, root, source, destination;
  final CanonicalPathAnchor anchor;
  final Map<String, String> mapping;
  final Map<String, WorkspaceFileSnapshot> snapshots;
  final Map<String, FileStat> identities;
  final List<String> inventory;
  final List<MarkdownMoveFile> files;
}

class MarkdownRecoveryFile {
  const MarkdownRecoveryFile(this.path, this.load, this.before);
  final String path;
  final WorkspaceFileLoad load;
  final List<int> before;
}

class MarkdownRecoveryPlan {
  MarkdownRecoveryPlan({
    required this.root,
    required this.journal,
    required this.journalSnapshot,
    required this.source,
    required this.destination,
    required this.moved,
    required List<MarkdownRecoveryFile> files,
  }) : files = List.unmodifiable(files);
  final String root, journal, source, destination;
  final WorkspaceFileSnapshot journalSnapshot;
  final bool moved;
  final List<MarkdownRecoveryFile> files;
}

/// Uses ordinary workspace publication and lossless destination edits. A durable
/// journal retains both versions if a process dies between file writes and move.
class MarkdownMoveService {
  const MarkdownMoveService({this.workspaceService = const WorkspaceService()});
  final WorkspaceService workspaceService;
  String remap(String path, String source, String destination) =>
      p.equals(path, source)
      ? destination
      : p.isWithin(source, path)
      ? p.join(destination, p.relative(path, from: source))
      : path;
  Future<MarkdownMovePlan> prepare(
    Workspace workspace,
    String source,
    String destination,
  ) async {
    final anchor = await captureCanonicalDirectoryAnchor(workspace.rootPath);
    if (!p.equals(anchor.rootPath, anchor.requestedRootPath)) {
      throw StateError('Workspace path changed.');
    }
    source = p.normalize(p.absolute(source));
    destination = p.normalize(p.absolute(destination));
    final from = await resolveAnchoredPath(anchor, source, allowRoot: false);
    final to = await resolveAnchoredPath(anchor, destination, allowRoot: false);
    if (from.type == FileSystemEntityType.notFound ||
        to.type != FileSystemEntityType.notFound ||
        p.isWithin(source, destination)) {
      throw StateError('The move destination is unavailable.');
    }
    if (workspace.writersideProject != null &&
        (from.type == FileSystemEntityType.directory ||
            workspace.writersideProject!.modules.any(
              (m) => m.topics.any((t) => p.equals(t.filePath, source)),
            ))) {
      throw StateError(
        'Use the established Writerside reviewed refactoring for owned topics.',
      );
    }
    final mapping = <String, String>{source: destination};
    if (from.type == FileSystemEntityType.directory) {
      await for (final entity in Directory(
        source,
      ).list(recursive: true, followLinks: false)) {
        await resolveAnchoredPath(anchor, entity.path, allowRoot: false);
        mapping[entity.path] = remap(entity.path, source, destination);
      }
    }
    final inventory = await _inventory(workspace.rootPath);
    final snapshots = <String, WorkspaceFileSnapshot>{};
    final identities = <String, FileStat>{};
    for (final path in mapping.keys) {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.file) {
        snapshots[path] = await workspaceService.fileSnapshot(path);
      }
    }
    final files = <MarkdownMoveFile>[];
    for (final path in inventory) {
      await resolveAnchoredPath(anchor, path, allowRoot: false);
      final load = await workspaceService.loadTextWithSnapshot(path);
      if (load.format.hasMixedLineEndings) {
        throw StateError('Review requires consistent line endings: $path');
      }
      final text = load.text;
      final references = await _scanMoveReferences(path, text);
      final edits = <int, MarkdownDestinationEdit>{};
      final movedSource = remap(path, source, destination);
      for (final ref in references) {
        final uri = Uri.tryParse(ref.destination);
        final span = ref.destinationSpan;
        if (uri == null ||
            uri.hasScheme ||
            uri.hasAuthority ||
            uri.path.isEmpty ||
            span == null) {
          continue;
        }
        final target = p.normalize(
          p.join(p.dirname(path), Uri.decodeComponent(uri.path)),
        );
        if (!p.isWithin(workspace.rootPath, target)) continue;
        final movedTarget = remap(target, source, destination);
        if (p.equals(path, movedSource) && p.equals(target, movedTarget)) {
          continue;
        }
        await resolveAnchoredPath(
          anchor,
          target,
          allowRoot: false,
          allowMissingAncestors: true,
        );
        var replacement = p
            .relative(movedTarget, from: p.dirname(movedSource))
            .split('/')
            .map(
              (part) => Uri.encodeComponent(
                part,
              ).replaceAll('(', '%28').replaceAll(')', '%29'),
            )
            .join('/');
        if (uri.hasQuery) replacement += '?${uri.query}';
        if (uri.hasFragment) replacement += '#${uri.fragment}';
        if (ref.kind == AuthoredReferenceKind.htmlLink ||
            ref.kind == AuthoredReferenceKind.htmlMedia) {
          replacement = const HtmlEscape(
            HtmlEscapeMode.attribute,
          ).convert(replacement);
        }
        final before = text.substring(span.startOffset, span.endOffset);
        if (before != replacement) {
          edits[span.startOffset] = MarkdownDestinationEdit(
            span.startOffset,
            span.endOffset,
            before,
            replacement,
          );
        }
      }
      snapshots[path] = load.snapshot;
      if (edits.isNotEmpty) {
        files.add(
          MarkdownMoveFile(
            path,
            load,
            edits.values.toList()..sort((a, b) => a.start.compareTo(b.start)),
          ),
        );
      }
    }
    for (final path in {...mapping.keys, ...snapshots.keys}) {
      identities[path] = await FileStat.stat(path);
    }
    return MarkdownMovePlan(
      workspaceId: workspace.id,
      root: workspace.rootPath,
      source: source,
      destination: destination,
      anchor: anchor,
      mapping: mapping,
      snapshots: snapshots,
      identities: identities,
      inventory: inventory,
      files: files,
    );
  }

  Future<List<String>> _inventory(String root) async {
    final paths = <String>[];
    final pending = <Directory>[Directory(root)];
    while (pending.isNotEmpty) {
      await for (final entity in pending.removeLast().list(
        followLinks: false,
      )) {
        if (const {'.git', '.hg', '.svn'}.contains(p.basename(entity.path))) {
          continue;
        }
        if (entity is Link) {
          final type = await FileSystemEntity.type(entity.path);
          if (type == FileSystemEntityType.directory ||
              {
                '.md',
                '.markdown',
              }.contains(p.extension(entity.path).toLowerCase())) {
            throw StateError(
              'Cannot inspect linked source safely: ${entity.path}',
            );
          }
        } else if (entity is Directory) {
          pending.add(entity);
        } else if (entity is File &&
            {
              '.md',
              '.markdown',
            }.contains(p.extension(entity.path).toLowerCase())) {
          paths.add(entity.path);
        }
      }
    }
    paths.sort();
    return paths;
  }

  Future<void> validate(MarkdownMovePlan plan) async {
    final inventory = await _inventory(plan.root);
    if (inventory.join('\n') != plan.inventory.join('\n')) {
      throw StateError('Workspace files changed; review again.');
    }
    final source = await resolveAnchoredPath(
      plan.anchor,
      plan.source,
      allowRoot: false,
    );
    final destination = await resolveAnchoredPath(
      plan.anchor,
      plan.destination,
      allowRoot: false,
    );
    if (source.type == FileSystemEntityType.notFound ||
        destination.type != FileSystemEntityType.notFound) {
      throw StateError('Move paths changed; review again.');
    }
    for (final entry in plan.snapshots.entries) {
      await resolveAnchoredPath(plan.anchor, entry.key, allowRoot: false);
      if ((await workspaceService.fileSnapshot(
        entry.key,
      )).differsFrom(entry.value)) {
        throw StateError('Reviewed file changed: ${entry.key}');
      }
    }
    for (final entry in plan.identities.entries) {
      final current = await FileStat.stat(entry.key);
      final before = entry.value;
      if (current.type != before.type ||
          current.changed != before.changed ||
          current.modified != before.modified ||
          current.mode != before.mode ||
          current.size != before.size) {
        throw StateError('Reviewed filesystem identity changed: ${entry.key}');
      }
    }
    if (source.type == FileSystemEntityType.directory) {
      final paths = <String>{plan.source};
      await for (final entity in Directory(
        plan.source,
      ).list(recursive: true, followLinks: false)) {
        await resolveAnchoredPath(plan.anchor, entity.path, allowRoot: false);
        paths.add(entity.path);
      }
      if (paths.length != plan.mapping.length ||
          !paths.containsAll(plan.mapping.keys)) {
        throw StateError('Moved folder membership changed; review again.');
      }
    }
  }

  Future<String> apply(
    MarkdownMovePlan plan, {
    required Future<String> Function() move,
    required void Function() validateBuffers,
  }) async {
    validateBuffers();
    await validate(plan);
    validateBuffers();
    final folder = p.join(plan.root, '.busymark-refactoring');
    await resolveAnchoredPath(plan.anchor, folder, allowRoot: false);
    await Directory(folder).create();
    final journal = File(p.join(folder, '${const Uuid().v4()}.json'));
    await const AtomicFileWriter().writeBytes(
      journal.path,
      utf8.encode(
        jsonEncode({
          'version': 1,
          'source': p.relative(plan.source, from: plan.root),
          'destination': p.relative(plan.destination, from: plan.root),
          'files': [
            for (final file in plan.files)
              {
                'path': p.relative(file.path, from: plan.root),
                'before': base64Encode(file.load.format.encode(file.load.text)),
                'after': base64Encode(file.load.format.encode(file.result)),
              },
          ],
        }),
      ),
      overwrite: false,
    );
    try {
      await validate(plan);
      validateBuffers();
      await workspaceService.saveFormattedTextBatch([
        for (final file in plan.files)
          WorkspaceBatchTextWrite(
            path: file.path,
            text: file.result,
            expectedSnapshot: file.load.snapshot,
            format: file.load.format,
          ),
      ], validateBeforeCommit: validateBuffers);
      validateBuffers();
      // Move revalidates canonical paths and collisions through WorkspaceService.
      final target = await move();
      if (!p.equals(target, plan.destination)) {
        throw StateError('Unexpected move result.');
      }
      await journal.delete();
      return target;
    } on Object {
      // Rollback compares exact post-operation bytes. Newer external content is
      // never replaced, and the journal survives any incomplete restoration.
      await recover(plan.root, journal.path);
      rethrow;
    }
  }

  Future<void> recover(
    String root,
    String journalPath, {
    bool undoMove = true,
  }) async {
    final plan = await prepareRecovery(root, journalPath);
    await recoverReviewed(plan, undoMove: undoMove);
  }

  Future<MarkdownRecoveryPlan> prepareRecovery(
    String root,
    String journalPath,
  ) async {
    final anchor = await captureCanonicalDirectoryAnchor(root);
    if (!p.equals(
          p.dirname(journalPath),
          p.join(root, '.busymark-refactoring'),
        ) ||
        p.extension(journalPath) != '.json') {
      throw StateError('Invalid refactoring journal location.');
    }
    await resolveAnchoredPath(anchor, journalPath, allowRoot: false);
    final journalSnapshot = await workspaceService.fileSnapshot(journalPath);
    final data =
        jsonDecode(await File(journalPath).readAsString())
            as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw StateError('Unsupported refactoring journal.');
    }
    String safe(Object? relative) {
      if (relative is! String ||
          p.isAbsolute(relative) ||
          p.split(relative).contains('..')) {
        throw StateError('Unsafe refactoring journal.');
      }
      return p.join(root, relative);
    }

    final source = safe(data['source']),
        destination = safe(data['destination']);
    await resolveAnchoredPath(anchor, source, allowRoot: false);
    await resolveAnchoredPath(anchor, destination, allowRoot: false);
    final moved =
        await FileSystemEntity.type(source, followLinks: false) ==
            FileSystemEntityType.notFound &&
        await FileSystemEntity.type(destination, followLinks: false) !=
            FileSystemEntityType.notFound;
    final files = <MarkdownRecoveryFile>[];
    for (final raw in data['files'] as List) {
      final original = safe(raw['path']);
      final path = moved ? remap(original, source, destination) : original;
      await resolveAnchoredPath(anchor, path, allowRoot: false);
      final current = await File(path).readAsBytes();
      final before = base64Decode(raw['before'] as String),
          after = base64Decode(raw['after'] as String);
      if (base64Encode(current) == base64Encode(before)) continue;
      if (base64Encode(current) != base64Encode(after)) {
        throw StateError('Recovery needs review of newer content: $path');
      }
      final load = await workspaceService.loadTextWithSnapshot(path);
      if (base64Encode(load.format.encode(load.text)) != base64Encode(after)) {
        throw StateError('Recovery source changed: $path');
      }
      files.add(MarkdownRecoveryFile(path, load, List.unmodifiable(before)));
    }
    if ((await workspaceService.fileSnapshot(
      journalPath,
    )).differsFrom(journalSnapshot)) {
      throw StateError('Recovery evidence changed.');
    }
    return MarkdownRecoveryPlan(
      root: root,
      journal: journalPath,
      journalSnapshot: journalSnapshot,
      source: source,
      destination: destination,
      moved: moved,
      files: files,
    );
  }

  Future<void> recoverReviewed(
    MarkdownRecoveryPlan plan, {
    bool undoMove = true,
    void Function()? validateBuffers,
  }) async {
    validateBuffers?.call();
    final anchor = await captureCanonicalDirectoryAnchor(plan.root);
    await resolveAnchoredPath(anchor, plan.journal, allowRoot: false);
    final currentPlan = await prepareRecovery(plan.root, plan.journal);
    if (currentPlan.moved != plan.moved ||
        currentPlan.source != plan.source ||
        currentPlan.destination != plan.destination ||
        currentPlan.journalSnapshot.differsFrom(plan.journalSnapshot) ||
        currentPlan.files.length != plan.files.length) {
      throw StateError('Recovery changed; review again.');
    }
    for (final file in plan.files) {
      await resolveAnchoredPath(anchor, file.path, allowRoot: false);
      if ((await workspaceService.fileSnapshot(
        file.path,
      )).differsFrom(file.load.snapshot)) {
        throw StateError('Recovery source changed: ${file.path}');
      }
    }
    validateBuffers?.call();
    await workspaceService.saveFormattedTextBatch([
      for (final file in plan.files)
        WorkspaceBatchTextWrite(
          path: file.path,
          text: decodeUtf8Document(file.before).text,
          format: decodeUtf8Document(file.before).format,
          expectedSnapshot: file.load.snapshot,
        ),
    ], validateBeforeCommit: validateBuffers);
    if (plan.moved && undoMove) {
      await resolveAnchoredPath(anchor, plan.source, allowRoot: false);
      await resolveAnchoredPath(anchor, plan.destination, allowRoot: false);
      if (await FileSystemEntity.type(plan.source, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw StateError('Recovery destination is occupied.');
      }
      final type = await FileSystemEntity.type(
        plan.destination,
        followLinks: false,
      );
      if (type == FileSystemEntityType.directory) {
        await Directory(plan.destination).rename(plan.source);
      } else {
        await File(plan.destination).rename(plan.source);
      }
    }
    await File(plan.journal).delete();
  }
}

Future<List<AuthoredReference>> _scanMoveReferences(String path, String text) =>
    Isolate.run(() => markdownReferences(identity: path, source: text));
