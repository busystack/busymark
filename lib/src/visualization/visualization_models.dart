import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

const visualizationSanitizerVersion = '4';
// Increment whenever BusyMark's rendering pipeline changes cached image bytes
// without changing the bundled third-party engine version.
const visualizationRenderPipelineVersion = '2';
const mermaidEngineVersion = '11.16.1';
const plantUmlEngineVersion = '1.2026.6';
const d2EngineVersion = '0.7.1';
const scalarOpenApiParserVersion = '0.28.14';
const scalarApiReferenceVersion = '1.65.1';
const scalarJsonMagicVersion = '0.13.0';
const yamlEngineVersion = '2.9.0';
const openApiEngineVersion =
    'parser:$scalarOpenApiParserVersion;bundle:$scalarJsonMagicVersion;yaml:$yamlEngineVersion';

enum VisualizationRendererKind { mermaid, plantUml, d2, openApi }

extension VisualizationRendererKindX on VisualizationRendererKind {
  String get canonicalFence => switch (this) {
    VisualizationRendererKind.mermaid => 'mermaid',
    VisualizationRendererKind.plantUml => 'plantuml',
    VisualizationRendererKind.d2 => 'd2',
    VisualizationRendererKind.openApi => 'openapi',
  };

  String get displayName => switch (this) {
    VisualizationRendererKind.mermaid => 'Mermaid',
    VisualizationRendererKind.plantUml => 'PlantUML',
    VisualizationRendererKind.d2 => 'D2',
    VisualizationRendererKind.openApi => 'OpenAPI',
  };

  String get engineVersion => switch (this) {
    VisualizationRendererKind.mermaid => mermaidEngineVersion,
    VisualizationRendererKind.plantUml => plantUmlEngineVersion,
    VisualizationRendererKind.d2 => d2EngineVersion,
    VisualizationRendererKind.openApi => openApiEngineVersion,
  };
}

@immutable
class VisualizationDescriptor {
  const VisualizationDescriptor({
    required this.kind,
    required this.originalLanguage,
    required this.canonicalLanguage,
  });

  factory VisualizationDescriptor.forFenceLanguage(String? language) {
    final original = language?.trim() ?? '';
    final normalized = original.toLowerCase();
    final kind = switch (normalized) {
      'mermaid' => VisualizationRendererKind.mermaid,
      'plantuml' || 'puml' => VisualizationRendererKind.plantUml,
      'd2' => VisualizationRendererKind.d2,
      'openapi' || 'oas' || 'swagger' => VisualizationRendererKind.openApi,
      _ => null,
    };
    if (kind == null) {
      throw ArgumentError.value(language, 'language', 'Unsupported fence');
    }
    return VisualizationDescriptor(
      kind: kind,
      originalLanguage: original,
      canonicalLanguage: kind.canonicalFence,
    );
  }

  static VisualizationDescriptor? maybeForFenceLanguage(String? language) {
    try {
      return VisualizationDescriptor.forFenceLanguage(language);
    } on ArgumentError {
      return null;
    }
  }

  final VisualizationRendererKind kind;
  final String originalLanguage;
  final String canonicalLanguage;
}

enum VisualizationTheme { light, dark }

enum VisualizationRenderProfile { preview, pdf, html }

enum VisualizationRenderPriority { visible, nearVisible, background, export }

@immutable
class VisualizationRendererOptions {
  const VisualizationRendererOptions(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> get canonicalValues => _canonicalMap(values);
}

@immutable
class VisualizationDependency {
  const VisualizationDependency({
    required this.id,
    required this.hash,
    required this.source,
  });

  final String id;
  final String hash;
  final String source;
}

@immutable
class VisualizationRenderRequest {
  const VisualizationRenderRequest({
    required this.blockKey,
    required this.kind,
    required this.source,
    required this.sourceStartLine,
    required this.documentPath,
    required this.workspaceRoot,
    required this.theme,
    required this.profile,
    required this.engineVersion,
    required this.editRevision,
    this.options = const VisualizationRendererOptions({}),
    this.dependencies = const [],
    this.priority = VisualizationRenderPriority.visible,
  });

  final String blockKey;
  final VisualizationRendererKind kind;
  final String source;
  final int sourceStartLine;
  final String documentPath;
  final String workspaceRoot;
  final VisualizationTheme theme;
  final VisualizationRenderProfile profile;
  final String engineVersion;
  final int editRevision;
  final VisualizationRendererOptions options;
  final List<VisualizationDependency> dependencies;
  final VisualizationRenderPriority priority;

  String get cacheKey {
    final sortedDependencies = dependencies.toList()
      ..sort((left, right) {
        final idOrder = left.id.compareTo(right.id);
        return idOrder != 0 ? idOrder : left.hash.compareTo(right.hash);
      });
    final payload = <String, Object?>{
      'renderer': kind.name,
      'engineVersion': engineVersion,
      'source': source,
      'theme': theme.name,
      'profile': profile.name,
      'options': options.canonicalValues,
      'sanitizerVersion': visualizationSanitizerVersion,
      'renderPipelineVersion': visualizationRenderPipelineVersion,
      'dependencies': [
        for (final dependency in sortedDependencies)
          {'id': dependency.id, 'hash': dependency.hash},
      ],
    };
    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }

  VisualizationRenderRequest copyWith({
    VisualizationRendererOptions? options,
    List<VisualizationDependency>? dependencies,
    VisualizationRenderPriority? priority,
  }) {
    return VisualizationRenderRequest(
      blockKey: blockKey,
      kind: kind,
      source: source,
      sourceStartLine: sourceStartLine,
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
      theme: theme,
      profile: profile,
      engineVersion: engineVersion,
      editRevision: editRevision,
      options: options ?? this.options,
      dependencies: dependencies ?? this.dependencies,
      priority: priority ?? this.priority,
    );
  }
}

enum VisualizationDiagnosticSeverity { error, warning, info }

@immutable
class VisualizationDiagnostic {
  const VisualizationDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.line,
    this.column,
    this.sourceId,
    this.sourceLine,
    this.sourceColumn,
  });

  factory VisualizationDiagnostic.fromJson(Map<Object?, Object?> json) {
    final severityName = json['severity'] as String?;
    return VisualizationDiagnostic(
      code: json['code'] as String? ?? 'visualization.error',
      message: json['message'] as String? ?? 'Visualization rendering failed.',
      severity: VisualizationDiagnosticSeverity.values.firstWhere(
        (value) => value.name == severityName,
        orElse: () => VisualizationDiagnosticSeverity.error,
      ),
      line: (json['line'] as num?)?.toInt(),
      column: (json['column'] as num?)?.toInt(),
      sourceId: json['sourceId'] as String?,
      sourceLine: (json['sourceLine'] as num?)?.toInt(),
      sourceColumn: (json['sourceColumn'] as num?)?.toInt(),
    );
  }

  final String code;
  final String message;
  final VisualizationDiagnosticSeverity severity;

  /// One-based line relative to the fenced block source.
  final int? line;

  /// One-based column relative to [line].
  final int? column;

  /// Dependency identifier when a diagnostic originates outside the fence.
  final String? sourceId;

  /// One-based location inside [sourceId].
  final int? sourceLine;
  final int? sourceColumn;

  int documentLine(int blockStartLine) => blockStartLine + (line ?? 1);

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    'severity': severity.name,
    if (line != null) 'line': line,
    if (column != null) 'column': column,
    if (sourceId != null) 'sourceId': sourceId,
    if (sourceLine != null) 'sourceLine': sourceLine,
    if (sourceColumn != null) 'sourceColumn': sourceColumn,
  };
}

sealed class VisualizationRenderResult {
  const VisualizationRenderResult({this.diagnostics = const []});

  final List<VisualizationDiagnostic> diagnostics;

  bool get isSuccessful =>
      this is SvgVisualizationResult ||
      this is RasterVisualizationResult ||
      this is OpenApiVisualizationResult;
}

@immutable
class SvgVisualizationResult extends VisualizationRenderResult {
  const SvgVisualizationResult({
    required this.svg,
    required this.width,
    required this.height,
    super.diagnostics,
  });

  final String svg;
  final double width;
  final double height;
}

@immutable
class RasterVisualizationResult extends VisualizationRenderResult {
  const RasterVisualizationResult({
    required this.pngBytes,
    required this.width,
    required this.height,
    this.pixelRatio = 1,
    super.diagnostics,
  }) : assert(pixelRatio > 0);

  final Uint8List pngBytes;
  final int width;
  final int height;

  /// Raster pixels per logical diagram unit.
  ///
  /// Preview rasters are normally generated at 2× so they remain sharp. The
  /// viewport uses this value to avoid treating resolution pixels as layout
  /// pixels when enforcing a readable initial scale.
  final double pixelRatio;
}

@immutable
class OpenApiOperation {
  const OpenApiOperation({
    required this.method,
    required this.path,
    required this.summary,
    required this.operationId,
    required this.tags,
  });

  factory OpenApiOperation.fromJson(Map<Object?, Object?> json) {
    return OpenApiOperation(
      method: json['method'] as String? ?? '',
      path: json['path'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      operationId: json['operationId'] as String? ?? '',
      tags: List.unmodifiable(
        (json['tags'] as List<Object?>? ?? const []).whereType<String>(),
      ),
    );
  }

  final String method;
  final String path;
  final String summary;
  final String operationId;
  final List<String> tags;

  Map<String, Object?> toJson() => {
    'method': method,
    'path': path,
    'summary': summary,
    'operationId': operationId,
    'tags': tags,
  };
}

@immutable
class OpenApiReferenceModel {
  const OpenApiReferenceModel({
    required this.title,
    required this.apiVersion,
    required this.specificationVersion,
    required this.valid,
    required this.serverCount,
    required this.pathCount,
    required this.operations,
    required this.tags,
    required this.document,
    this.externalDocuments = const [],
  });

  factory OpenApiReferenceModel.fromJson(Map<Object?, Object?> json) {
    return OpenApiReferenceModel(
      title: json['title'] as String? ?? 'OpenAPI',
      apiVersion: json['apiVersion'] as String? ?? '',
      specificationVersion: json['specificationVersion'] as String? ?? '',
      valid: json['valid'] as bool? ?? false,
      serverCount: (json['serverCount'] as num?)?.toInt() ?? 0,
      pathCount: (json['pathCount'] as num?)?.toInt() ?? 0,
      operations: List.unmodifiable(
        (json['operations'] as List<Object?>? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(OpenApiOperation.fromJson),
      ),
      tags: List.unmodifiable(
        (json['tags'] as List<Object?>? ?? const []).whereType<String>(),
      ),
      document: Map.unmodifiable(
        (json['document'] as Map<Object?, Object?>? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      externalDocuments: List.unmodifiable(
        (json['externalDocuments'] as List<Object?>? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(OpenApiExternalDocument.fromJson),
      ),
    );
  }

  final String title;
  final String apiVersion;
  final String specificationVersion;
  final bool valid;
  final int serverCount;
  final int pathCount;
  final List<OpenApiOperation> operations;
  final List<String> tags;
  final Map<String, Object?> document;
  final List<OpenApiExternalDocument> externalDocuments;

  int get operationCount => operations.length;

  Map<String, Object?> toJson() => {
    'title': title,
    'apiVersion': apiVersion,
    'specificationVersion': specificationVersion,
    'valid': valid,
    'serverCount': serverCount,
    'pathCount': pathCount,
    'operations': [for (final operation in operations) operation.toJson()],
    'tags': tags,
    'document': document,
    'externalDocuments': [
      for (final externalDocument in externalDocuments)
        externalDocument.toJson(),
    ],
  };
}

@immutable
class OpenApiExternalDocument {
  const OpenApiExternalDocument({required this.id, required this.document});

  factory OpenApiExternalDocument.fromJson(Map<Object?, Object?> json) {
    return OpenApiExternalDocument(
      id: json['id'] as String? ?? '',
      document: Map.unmodifiable(
        (json['document'] as Map<Object?, Object?>? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
    );
  }

  final String id;
  final Map<String, Object?> document;

  Map<String, Object?> toJson() => {'id': id, 'document': document};
}

@immutable
class OpenApiVisualizationResult extends VisualizationRenderResult {
  const OpenApiVisualizationResult({
    required this.reference,
    required this.content,
    this.entryId = 'document.openapi',
    this.dependencies = const [],
    super.diagnostics,
  });

  final OpenApiReferenceModel reference;
  final String content;
  final String entryId;
  final List<VisualizationDependency> dependencies;
}

@immutable
class UnsupportedVisualizationResult extends VisualizationRenderResult {
  const UnsupportedVisualizationResult({
    required this.feature,
    required super.diagnostics,
  });

  final String feature;
}

@immutable
class FailedVisualizationResult extends VisualizationRenderResult {
  const FailedVisualizationResult({
    required this.code,
    required this.message,
    this.retryable = true,
    super.diagnostics,
  });

  final String code;
  final String message;
  final bool retryable;
}

Map<String, Object?> _canonicalMap(Map<String, Object?> input) {
  final keys = input.keys.toList()..sort();
  return {for (final key in keys) key: _canonicalValue(input[key])};
}

Object? _canonicalValue(Object? value) {
  if (value is Map<String, Object?>) {
    return _canonicalMap(value);
  }
  if (value is Map) {
    return _canonicalMap(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  }
  if (value is Iterable) {
    return [for (final item in value) _canonicalValue(item)];
  }
  return value;
}
