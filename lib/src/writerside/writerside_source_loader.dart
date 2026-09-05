import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../markdown/busymark_document.dart';
import 'writerside_document.dart';
import 'writerside_model.dart';

const writersideResolvedSourceAttribute = 'busymark-resolved-source';

class WritersideSourceFile {
  const WritersideSourceFile({this.path, this.text, this.failure});
  final String? path;
  final String? text;
  final String? failure;
}

/// One guarded contract for textual inputs. Paths stay relative until validated;
/// resolved text travels with the semantic block through preview and export.
class WritersideSourceLoader {
  const WritersideSourceLoader({this.maximumBytes = 2 * 1024 * 1024});
  final int maximumBytes;

  static String key(String topicPath, String reference) =>
      '$topicPath\u0000$reference';

  Future<WritersideSourceFile> load({
    required String reference,
    required String documentPath,
    required String workspaceRoot,
    Iterable<String> directories = const [],
    Map<String, String> overrides = const {},
  }) async {
    final value = reference.trim();
    if (value.isEmpty ||
        value.contains('\u0000') ||
        p.isAbsolute(value) ||
        (Uri.tryParse(value)?.hasScheme ?? false)) {
      return const WritersideSourceFile(failure: 'invalid-reference');
    }
    try {
      final anchor = await captureCanonicalDirectoryAnchor(workspaceRoot);
      for (final candidate in <String>{
        p.normalize(p.join(p.dirname(documentPath), value)),
        for (final directory in directories)
          p.normalize(p.join(workspaceRoot, directory, value)),
      }) {
        try {
          final resolved = await resolveAnchoredPath(
            anchor,
            candidate,
            allowRoot: false,
          );
          final override = overrides[candidate] ?? overrides[resolved.path];
          if (resolved.type != FileSystemEntityType.file && override == null) {
            continue;
          }
          if (override != null) {
            if (utf8.encode(override).length > maximumBytes) {
              return const WritersideSourceFile(failure: 'too-large');
            }
            return WritersideSourceFile(path: resolved.path, text: override);
          }
          final file = File(resolved.path);
          if (await file.length() > maximumBytes) {
            return const WritersideSourceFile(failure: 'too-large');
          }
          final bytes = await file.readAsBytes();
          if (bytes.length > maximumBytes) {
            return const WritersideSourceFile(failure: 'too-large');
          }
          return WritersideSourceFile(
            path: resolved.path,
            text: utf8.decode(bytes, allowMalformed: false),
          );
        } on AnchoredPathViolation catch (error) {
          if (error.reason == AnchoredPathViolationReason.missingAncestor) {
            continue;
          }
          return const WritersideSourceFile(failure: 'outside-workspace');
        } on FileSystemException {
          continue;
        } on FormatException {
          return const WritersideSourceFile(failure: 'invalid-utf8');
        }
      }
      return const WritersideSourceFile(failure: 'missing');
    } on AnchoredPathViolation {
      return const WritersideSourceFile(failure: 'outside-workspace');
    } on FileSystemException {
      return const WritersideSourceFile(failure: 'missing');
    }
  }

  Future<Map<String, WritersideSourceFile>> loadModule(
    WritersideModule module,
  ) async {
    final result = <String, WritersideSourceFile>{};
    Future<void> add(String path, Map<String, String> attributes) async {
      final reference = attributes['src'];
      if (reference == null || reference.isEmpty) return;
      final identity = key(path, reference);
      if (result.containsKey(identity)) return;
      result[identity] = await load(
        reference: reference,
        documentPath: path,
        workspaceRoot: module.rootPath,
        directories: [
          if (module.config.snippetsDir case final dir?) dir,
          module.config.apiSpecificationsDir,
        ],
        overrides: module.sourceOverrides,
      );
    }

    Future<void> blocks(String path, List<BusyBlock> values) async {
      for (final block in values) {
        if (block.kind == BusyBlockKind.codeBlock) {
          await add(path, block.attributes);
        }
        await blocks(path, block.children);
      }
    }

    for (final topic in module.topics) {
      for (final node in topic.document.walk()) {
        if (node is WritersideElementNode &&
            {
              'code-block',
              'api-doc',
              'api-endpoint',
              'api-schema',
              'api-webhook',
              'sample',
            }.contains(node.name)) {
          await add(topic.filePath, node.attributes);
        } else if (node is WritersideMarkdownBlockNode) {
          await blocks(topic.filePath, [node.block]);
        }
      }
    }
    return Map.unmodifiable(result);
  }
}
