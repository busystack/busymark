import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'visualization_models.dart';

class VisualizationCache {
  VisualizationCache({
    Directory? diskRoot,
    this.maximumMemoryEntries = 64,
    this.maximumDiskEntries = 256,
    this.maximumDiskBytes = 256 * 1024 * 1024,
    this.maximumEntryBytes = 32 * 1024 * 1024,
    Map<String, String>? environment,
  }) : diskRoot = diskRoot ?? _defaultDiskRoot(environment);

  final Directory diskRoot;
  final int maximumMemoryEntries;
  final int maximumDiskEntries;
  final int maximumDiskBytes;
  final int maximumEntryBytes;

  final LinkedHashMap<String, VisualizationRenderResult> _memory =
      LinkedHashMap();

  Future<VisualizationRenderResult?> get(String key) async {
    final memoryResult = _memory.remove(key);
    if (memoryResult != null) {
      _memory[key] = memoryResult;
      return memoryResult;
    }
    final file = _fileForKey(key);
    try {
      if (!await file.exists()) {
        return null;
      }
      final stat = await file.stat();
      if (stat.size <= 0 || stat.size > maximumEntryBytes) {
        await _deleteInvalidEntry(file);
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?> ||
          decoded['schemaVersion'] != 1 ||
          decoded['key'] != key) {
        await _deleteInvalidEntry(file);
        return null;
      }
      final result = _decodeResult(decoded);
      if (result != null) {
        _remember(key, result);
        unawaitedBestEffort(file.setLastModified(DateTime.now()));
      } else {
        await _deleteInvalidEntry(file);
      }
      return result;
    } on Object {
      await _deleteInvalidEntry(file);
      return null;
    }
  }

  Future<void> put(String key, VisualizationRenderResult result) async {
    if (!result.isSuccessful) {
      return;
    }
    final encoded = jsonEncode(_encodeResult(key, result));
    final bytes = utf8.encode(encoded);
    if (bytes.length > maximumEntryBytes) {
      return;
    }
    _remember(key, result);
    try {
      await diskRoot.create(recursive: true);
      final file = _fileForKey(key);
      if (!await file.exists()) {
        final temporary = File(
          '${file.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
        );
        await temporary.writeAsBytes(bytes, flush: true);
        try {
          await temporary.rename(file.path);
        } on FileSystemException {
          if (await temporary.exists()) {
            await temporary.delete();
          }
        }
      }
      await _trimDiskBestEffort();
    } on Object {
      // Cache failures must never fail rendering.
    }
  }

  void _remember(String key, VisualizationRenderResult result) {
    _memory.remove(key);
    _memory[key] = result;
    while (_memory.length > maximumMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  File _fileForKey(String key) => File(p.join(diskRoot.path, '$key.json'));

  Future<void> _deleteInvalidEntry(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on Object {
      // A cache miss remains safe even when the invalid file is read-only.
    }
  }

  Future<void> _trimDiskBestEffort() async {
    try {
      final files = <({File file, FileStat stat})>[];
      await for (final entity in diskRoot.list(followLinks: false)) {
        if (entity is! File || p.extension(entity.path) != '.json') {
          continue;
        }
        final stat = await entity.stat();
        files.add((file: entity, stat: stat));
      }
      files.sort(
        (left, right) => left.stat.modified.compareTo(right.stat.modified),
      );
      var bytes = files.fold<int>(0, (sum, entry) => sum + entry.stat.size);
      var count = files.length;
      for (final entry in files) {
        if (count <= maximumDiskEntries && bytes <= maximumDiskBytes) {
          break;
        }
        await entry.file.delete();
        count--;
        bytes -= entry.stat.size;
      }
    } on Object {
      // Best-effort LRU maintenance only.
    }
  }

  static Directory _defaultDiskRoot(Map<String, String>? environment) {
    final effectiveEnvironment = environment ?? Platform.environment;
    final configured = effectiveEnvironment['XDG_CACHE_HOME'];
    final base = configured != null && configured.trim().isNotEmpty
        ? configured
        : p.join(
            effectiveEnvironment['HOME'] ?? Directory.systemTemp.path,
            '.cache',
          );
    return Directory(p.join(base, 'busymark', 'visualizations', 'v1'));
  }
}

Map<String, Object?> _encodeResult(
  String key,
  VisualizationRenderResult result,
) {
  final base = <String, Object?>{
    'schemaVersion': 1,
    'key': key,
    'diagnostics': [
      for (final diagnostic in result.diagnostics) diagnostic.toJson(),
    ],
  };
  return switch (result) {
    SvgVisualizationResult() => {
      ...base,
      'type': 'svg',
      'svg': result.svg,
      'width': result.width,
      'height': result.height,
    },
    RasterVisualizationResult() => {
      ...base,
      'type': 'raster',
      'png': base64Encode(result.pngBytes),
      'width': result.width,
      'height': result.height,
      'pixelRatio': result.pixelRatio,
    },
    OpenApiVisualizationResult() => {
      ...base,
      'type': 'openapi',
      'content': result.content,
      'entryId': result.entryId,
      'dependencies': [
        for (final dependency in result.dependencies)
          {
            'id': dependency.id,
            'hash': dependency.hash,
            'source': dependency.source,
          },
      ],
      'reference': result.reference.toJson(),
    },
    _ => base,
  };
}

VisualizationRenderResult? _decodeResult(Map<String, Object?> json) {
  final diagnostics = List<VisualizationDiagnostic>.unmodifiable(
    (json['diagnostics'] as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(VisualizationDiagnostic.fromJson),
  );
  return switch (json['type']) {
    'svg' when json['svg'] is String => SvgVisualizationResult(
      svg: json['svg']! as String,
      width: (json['width'] as num?)?.toDouble() ?? 1,
      height: (json['height'] as num?)?.toDouble() ?? 1,
      diagnostics: diagnostics,
    ),
    'raster' when json['png'] is String => RasterVisualizationResult(
      pngBytes: Uint8List.fromList(base64Decode(json['png']! as String)),
      width: (json['width'] as num?)?.toInt() ?? 1,
      height: (json['height'] as num?)?.toInt() ?? 1,
      pixelRatio: (json['pixelRatio'] as num?)?.toDouble() ?? 1,
      diagnostics: diagnostics,
    ),
    'openapi'
        when json['content'] is String &&
            json['reference'] is Map<Object?, Object?> =>
      OpenApiVisualizationResult(
        content: json['content']! as String,
        entryId: json['entryId'] as String? ?? 'document.openapi',
        dependencies: List.unmodifiable(
          (json['dependencies'] as List<Object?>? ?? const [])
              .whereType<Map<Object?, Object?>>()
              .map(
                (item) => VisualizationDependency(
                  id: item['id'] as String? ?? '',
                  hash: item['hash'] as String? ?? '',
                  source: item['source'] as String? ?? '',
                ),
              )
              .where((dependency) => dependency.id.isNotEmpty),
        ),
        reference: OpenApiReferenceModel.fromJson(
          json['reference']! as Map<Object?, Object?>,
        ),
        diagnostics: diagnostics,
      ),
    _ => null,
  };
}

void unawaitedBestEffort(Future<void> operation) {
  operation.catchError((Object _) {});
}
