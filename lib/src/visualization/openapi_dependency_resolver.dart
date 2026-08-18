import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import 'visualization_models.dart';
import 'visualization_renderer.dart';
import 'web_render_host.dart';

class OpenApiDependencyResolver {
  const OpenApiDependencyResolver({
    required this.host,
    this.maximumFiles = 32,
    this.maximumFileBytes = 4 * 1024 * 1024,
    this.maximumTotalBytes = 16 * 1024 * 1024,
  });

  final WebRenderHost host;
  final int maximumFiles;
  final int maximumFileBytes;
  final int maximumTotalBytes;

  Future<VisualizationRenderRequest> resolve(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final documentPath = request.documentPath.trim();
    final requestedRoot = request.workspaceRoot.trim().isNotEmpty
        ? request.workspaceRoot
        : documentPath.isEmpty
        ? ''
        : p.dirname(documentPath);
    final entryId = documentPath.isEmpty || requestedRoot.isEmpty
        ? 'document.openapi'
        : _portableId(p.relative(documentPath, from: requestedRoot));
    final initialReferences = await host.inspectOpenApiReferences(
      request.source,
      cancellationToken,
    );
    cancellationToken.throwIfCancelled();
    if (initialReferences.every(_isInternalReference)) {
      return request.copyWith(
        options: VisualizationRendererOptions({
          ...request.options.values,
          'openApiEntryId': entryId,
        }),
      );
    }
    if (documentPath.isEmpty || requestedRoot.isEmpty) {
      final reference = initialReferences.firstWhere(
        (item) => !_isInternalReference(item),
      );
      throw OpenApiDependencyException(
        'visualization.openapiUnsavedReference',
        'Save the document before using local OpenAPI references.',
        line: reference.line,
        column: reference.column,
      );
    }

    final anchor = await captureCanonicalDirectoryAnchor(requestedRoot);
    final entryResolution = await resolveAnchoredPath(
      anchor,
      documentPath,
      allowRoot: false,
    );
    if (entryResolution.type != FileSystemEntityType.file) {
      throw const OpenApiDependencyException(
        'visualization.openapiDocumentUnavailable',
        'The OpenAPI document path is not a regular file.',
      );
    }
    final canonicalEntryId = _portableId(
      p.relative(entryResolution.path, from: anchor.rootPath),
    );
    final pending = <_PendingOpenApiFile>[
      _PendingOpenApiFile(
        id: canonicalEntryId,
        absolutePath: entryResolution.path,
        source: request.source,
        references: initialReferences,
        entrypoint: true,
      ),
    ];
    final byId = <String, _PendingOpenApiFile>{canonicalEntryId: pending.first};
    var totalBytes = utf8.encode(request.source).length;

    for (var index = 0; index < pending.length; index++) {
      cancellationToken.throwIfCancelled();
      final current = pending[index];
      for (final reference in current.references) {
        if (_isInternalReference(reference)) {
          continue;
        }
        final referencePath = _localReferencePath(reference);
        final candidate = p.normalize(
          p.join(p.dirname(current.absolutePath), referencePath),
        );
        late AnchoredPathResolution resolution;
        try {
          resolution = await resolveAnchoredPath(
            anchor,
            candidate,
            allowRoot: false,
          );
        } on AnchoredPathViolation {
          throw _referenceError(
            'visualization.openapiUnsafeReference',
            'The OpenAPI reference resolves outside the workspace or through a symbolic link.',
            reference,
          );
        }
        if (resolution.type != FileSystemEntityType.file) {
          throw _referenceError(
            'visualization.openapiReferenceNotFound',
            'OpenAPI reference not found: $referencePath',
            reference,
          );
        }
        final id = _portableId(
          p.relative(resolution.path, from: anchor.rootPath),
        );
        if (byId.containsKey(id)) {
          continue;
        }
        if (byId.length >= maximumFiles) {
          throw _referenceError(
            'visualization.openapiReferenceLimit',
            'OpenAPI local reference count exceeds the limit.',
            reference,
          );
        }
        final file = File(resolution.path);
        late int size;
        try {
          size = await file.length();
        } on FileSystemException {
          throw _referenceError(
            'visualization.openapiReferenceUnavailable',
            'OpenAPI reference could not be read: $referencePath',
            reference,
          );
        }
        if (size > maximumFileBytes || totalBytes + size > maximumTotalBytes) {
          throw _referenceError(
            'visualization.openapiReferenceTooLarge',
            'OpenAPI local references exceed the size limit.',
            reference,
          );
        }
        late String source;
        try {
          source = utf8.decode(await file.readAsBytes());
        } on FormatException {
          throw _referenceError(
            'visualization.openapiReferenceEncoding',
            'OpenAPI reference is not valid UTF-8: $referencePath',
            reference,
          );
        } on FileSystemException {
          throw _referenceError(
            'visualization.openapiReferenceUnavailable',
            'OpenAPI reference could not be read: $referencePath',
            reference,
          );
        }
        cancellationToken.throwIfCancelled();
        final references = await host.inspectOpenApiReferences(
          source,
          cancellationToken,
        );
        cancellationToken.throwIfCancelled();
        final dependency = _PendingOpenApiFile(
          id: id,
          absolutePath: resolution.path,
          source: source,
          references: references,
          entrypoint: false,
        );
        byId[id] = dependency;
        pending.add(dependency);
        totalBytes += size;
      }
    }

    final dependencies = [
      for (final file in pending.where((file) => !file.entrypoint))
        VisualizationDependency(
          id: file.id,
          hash: sha256.convert(utf8.encode(file.source)).toString(),
          source: file.source,
        ),
    ]..sort((left, right) => left.id.compareTo(right.id));
    return request.copyWith(
      dependencies: List.unmodifiable(dependencies),
      options: VisualizationRendererOptions({
        ...request.options.values,
        'openApiEntryId': canonicalEntryId,
      }),
    );
  }

  bool _isInternalReference(OpenApiSourceReference reference) =>
      reference.value.trim().isEmpty || reference.value.trim().startsWith('#');

  String _localReferencePath(OpenApiSourceReference reference) {
    final value = reference.value;
    final trimmed = value.trim();
    final prefix = trimmed.split('#').first;
    if (prefix.isEmpty ||
        prefix.startsWith('//') ||
        p.isAbsolute(prefix) ||
        prefix.contains('\\')) {
      throw _referenceError(
        'visualization.openapiRemoteReference',
        'Only relative local OpenAPI references are allowed: $value',
        reference,
      );
    }
    late Uri uri;
    try {
      uri = Uri.parse(prefix);
    } on FormatException {
      throw _referenceError(
        'visualization.openapiInvalidReference',
        'Invalid OpenAPI reference: $value',
        reference,
      );
    }
    if (uri.hasScheme || uri.hasAuthority || uri.query.isNotEmpty) {
      throw _referenceError(
        'visualization.openapiRemoteReference',
        'Remote OpenAPI references are not allowed: $value',
        reference,
      );
    }
    late String decoded;
    try {
      decoded = Uri.decodeComponent(uri.path);
    } on FormatException {
      throw _referenceError(
        'visualization.openapiInvalidReference',
        'Invalid OpenAPI reference: $value',
        reference,
      );
    }
    if (decoded.contains(r'\')) {
      throw _referenceError(
        'visualization.openapiInvalidReference',
        'OpenAPI references must use portable forward-slash paths: $value',
        reference,
      );
    }
    final extension = p.extension(decoded).toLowerCase();
    if (!const {'.yaml', '.yml', '.json'}.contains(extension)) {
      throw _referenceError(
        'visualization.openapiReferenceType',
        'OpenAPI references must use .yaml, .yml, or .json files: $value',
        reference,
      );
    }
    return decoded;
  }

  String _portableId(String path) => p.posix.joinAll(p.split(path));

  OpenApiDependencyException _referenceError(
    String code,
    String message,
    OpenApiSourceReference reference,
  ) {
    return OpenApiDependencyException(
      code,
      message,
      line: reference.line,
      column: reference.column,
    );
  }
}

class OpenApiDependencyException implements Exception {
  const OpenApiDependencyException(
    this.code,
    this.message, {
    this.line,
    this.column,
  });

  final String code;
  final String message;
  final int? line;
  final int? column;

  @override
  String toString() => '$code: $message';
}

class _PendingOpenApiFile {
  const _PendingOpenApiFile({
    required this.id,
    required this.absolutePath,
    required this.source,
    required this.references,
    required this.entrypoint,
  });

  final String id;
  final String absolutePath;
  final String source;
  final List<OpenApiSourceReference> references;
  final bool entrypoint;
}
