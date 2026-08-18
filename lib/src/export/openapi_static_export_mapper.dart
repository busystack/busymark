import '../visualization/visualization_models.dart';
import 'markdown_export_document.dart';

class OpenApiStaticExportMapper {
  const OpenApiStaticExportMapper();

  static const _httpMethods = {
    'get',
    'put',
    'post',
    'delete',
    'options',
    'head',
    'patch',
    'trace',
  };

  MarkdownExportBlock map(OpenApiReferenceModel reference) {
    final blocks = <MarkdownExportBlock>[
      _heading(2, '${reference.title} API Reference'),
      _table(
        const ['Field', 'Value'],
        [
          ['API version', reference.apiVersion],
          ['Specification', reference.specificationVersion],
          ['Validation', reference.valid ? 'Valid' : 'Invalid'],
          ['Paths', '${reference.pathCount}'],
          ['Operations', '${reference.operationCount}'],
        ],
      ),
    ];
    final root = reference.document;
    _addText(blocks, _string(_map(root['info'])['description']));
    _addServers(blocks, root);
    _addSecurityRequirement(blocks, root['security'], headingLevel: 3);
    _addOperations(blocks, root);

    final documents = <({String id, Map<String, Object?> document})>[
      (id: '', document: root),
      for (final external in reference.externalDocuments)
        (id: external.id, document: external.document),
    ];
    _addReusableComponents(blocks, documents);
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.openApiReference,
      children: List.unmodifiable(blocks),
      attributes: {'title': reference.title},
    );
  }

  void _addServers(
    List<MarkdownExportBlock> blocks,
    Map<String, Object?> document,
  ) {
    final rows = <List<String>>[];
    for (final server in _list(document['servers']).map(_map)) {
      final url = _string(server['url']);
      if (url.isNotEmpty) {
        rows.add([url, _string(server['description'])]);
      }
    }
    if (rows.isEmpty && _string(document['host']).isNotEmpty) {
      final schemes = _list(
        document['schemes'],
      ).map(_string).where((value) => value.isNotEmpty).toList();
      final scheme = schemes.isEmpty ? 'https' : schemes.first;
      rows.add([
        '$scheme://${_string(document['host'])}${_string(document['basePath'])}',
        '',
      ]);
    }
    if (rows.isEmpty) {
      return;
    }
    blocks
      ..add(_heading(3, 'Servers'))
      ..add(_table(const ['URL', 'Description'], rows));
  }

  void _addOperations(
    List<MarkdownExportBlock> blocks,
    Map<String, Object?> document,
  ) {
    final paths = _map(document['paths']);
    if (paths.isEmpty) {
      return;
    }
    blocks.add(_heading(3, 'Operations'));
    for (final pathEntry in paths.entries) {
      final pathItem = _map(pathEntry.value);
      final inheritedParameters = _list(pathItem['parameters']);
      for (final operationEntry in pathItem.entries) {
        final method = operationEntry.key.toLowerCase();
        if (!_httpMethods.contains(method)) {
          continue;
        }
        final operation = _map(operationEntry.value);
        if (operation.isEmpty) {
          continue;
        }
        blocks.add(_heading(4, '${method.toUpperCase()} ${pathEntry.key}'));
        final summary = _string(operation['summary']);
        final description = _string(operation['description']);
        _addText(blocks, summary);
        if (description != summary) {
          _addText(blocks, description);
        }
        final metadata = <List<String>>[];
        _addMetadataRow(metadata, 'Operation ID', operation['operationId']);
        _addMetadataRow(metadata, 'Tags', _list(operation['tags']).join(', '));
        if (operation['deprecated'] == true) {
          metadata.add(const ['Deprecated', 'Yes']);
        }
        final security = _securityLabel(operation['security']);
        if (security.isNotEmpty) {
          metadata.add(['Security', security]);
        }
        if (metadata.isNotEmpty) {
          blocks.add(_table(const ['Field', 'Value'], metadata));
        }

        final parameters = [
          ...inheritedParameters,
          ..._list(operation['parameters']),
        ];
        _addParameters(blocks, parameters, headingLevel: 5);
        _addRequestBody(blocks, operation['requestBody'], headingLevel: 5);
        _addResponses(blocks, operation['responses'], headingLevel: 5);

        final callbacks = _map(operation['callbacks']);
        if (callbacks.isNotEmpty) {
          blocks
            ..add(_heading(5, 'Callbacks'))
            ..add(_paragraph(callbacks.keys.join(', ')));
        }
      }
    }
  }

  void _addParameters(
    List<MarkdownExportBlock> blocks,
    List<Object?> parameters, {
    required int headingLevel,
  }) {
    final rows = <List<String>>[];
    for (final value in parameters) {
      final parameter = _map(value);
      final reference = _string(parameter[r'$ref']);
      if (reference.isNotEmpty) {
        rows.add([reference, '', '', '', 'Reusable parameter reference']);
        continue;
      }
      rows.add([
        _string(parameter['name']),
        _string(parameter['in']),
        parameter['required'] == true ? 'Yes' : 'No',
        _schemaLabel(parameter['schema']).isNotEmpty
            ? _schemaLabel(parameter['schema'])
            : _string(parameter['type']),
        _string(parameter['description']),
      ]);
    }
    if (rows.isEmpty) {
      return;
    }
    blocks
      ..add(_heading(headingLevel, 'Parameters'))
      ..add(
        _table(const ['Name', 'In', 'Required', 'Type', 'Description'], rows),
      );
  }

  void _addRequestBody(
    List<MarkdownExportBlock> blocks,
    Object? value, {
    required int headingLevel,
  }) {
    final requestBody = _map(value);
    if (requestBody.isEmpty) {
      return;
    }
    blocks.add(_heading(headingLevel, 'Request body'));
    final reference = _string(requestBody[r'$ref']);
    if (reference.isNotEmpty) {
      blocks.add(_paragraph(reference));
      return;
    }
    _addText(blocks, _string(requestBody['description']));
    if (requestBody['required'] == true) {
      blocks.add(_paragraph('Required: Yes'));
    }
    final rows = <List<String>>[];
    for (final content in _map(requestBody['content']).entries) {
      rows.add([content.key, _schemaLabel(_map(content.value)['schema'])]);
    }
    if (rows.isNotEmpty) {
      blocks.add(_table(const ['Content type', 'Schema'], rows));
    }
  }

  void _addResponses(
    List<MarkdownExportBlock> blocks,
    Object? value, {
    required int headingLevel,
  }) {
    final responses = _map(value);
    if (responses.isEmpty) {
      return;
    }
    final rows = <List<String>>[];
    for (final responseEntry in responses.entries) {
      final response = _map(responseEntry.value);
      final content = _map(response['content']);
      final contentTypes = content.keys.join(', ');
      final schemas = <String>{};
      for (final media in content.values.map(_map)) {
        final schema = _schemaLabel(media['schema']);
        if (schema.isNotEmpty) {
          schemas.add(schema);
        }
      }
      final swaggerSchema = _schemaLabel(response['schema']);
      if (swaggerSchema.isNotEmpty) {
        schemas.add(swaggerSchema);
      }
      rows.add([
        responseEntry.key,
        _string(response['description']),
        contentTypes,
        schemas.join(', '),
      ]);
    }
    blocks
      ..add(_heading(headingLevel, 'Responses'))
      ..add(
        _table(const ['Status', 'Description', 'Content type', 'Schema'], rows),
      );
  }

  void _addReusableComponents(
    List<MarkdownExportBlock> blocks,
    List<({String id, Map<String, Object?> document})> documents,
  ) {
    final securityRows = <List<String>>[];
    final schemaSections = <MarkdownExportBlock>[];
    final parameterSections = <MarkdownExportBlock>[];
    final requestBodySections = <MarkdownExportBlock>[];
    for (final entry in documents) {
      final components = _map(entry.document['components']);
      final sourcePrefix = entry.id.isEmpty ? '' : '${entry.id}: ';
      final securitySchemes = {
        ..._map(entry.document['securityDefinitions']),
        ..._map(components['securitySchemes']),
      };
      for (final schemeEntry in securitySchemes.entries) {
        final scheme = _map(schemeEntry.value);
        securityRows.add([
          '$sourcePrefix${schemeEntry.key}',
          _string(scheme['type']),
          _firstNonEmpty([
            _string(scheme['scheme']),
            _string(scheme['in']),
            _string(scheme['openIdConnectUrl']),
          ]),
          _string(scheme['description']),
        ]);
      }

      final schemas = {
        ..._map(entry.document['definitions']),
        ..._map(components['schemas']),
      };
      for (final schemaEntry in schemas.entries) {
        schemaSections.addAll(
          _schemaBlocks(
            '$sourcePrefix${schemaEntry.key}',
            _map(schemaEntry.value),
          ),
        );
      }

      for (final parameterEntry in _map(components['parameters']).entries) {
        parameterSections.add(
          _heading(4, '$sourcePrefix${parameterEntry.key}'),
        );
        _addParameters(parameterSections, [
          parameterEntry.value,
        ], headingLevel: 5);
      }
      for (final bodyEntry in _map(components['requestBodies']).entries) {
        requestBodySections.add(_heading(4, '$sourcePrefix${bodyEntry.key}'));
        _addRequestBody(requestBodySections, bodyEntry.value, headingLevel: 5);
      }
    }

    if (securityRows.isNotEmpty) {
      blocks
        ..add(_heading(3, 'Security schemes'))
        ..add(
          _table(const [
            'Name',
            'Type',
            'Scheme or location',
            'Description',
          ], securityRows),
        );
    }
    if (parameterSections.isNotEmpty) {
      blocks
        ..add(_heading(3, 'Reusable parameters'))
        ..addAll(parameterSections);
    }
    if (requestBodySections.isNotEmpty) {
      blocks
        ..add(_heading(3, 'Reusable request bodies'))
        ..addAll(requestBodySections);
    }
    if (schemaSections.isNotEmpty) {
      blocks
        ..add(_heading(3, 'Schemas'))
        ..addAll(schemaSections);
    }
  }

  List<MarkdownExportBlock> _schemaBlocks(
    String name,
    Map<String, Object?> schema,
  ) {
    final blocks = <MarkdownExportBlock>[_heading(4, name)];
    _addText(blocks, _string(schema['description']));
    final details = <List<String>>[];
    _addMetadataRow(details, 'Type', _schemaLabel(schema));
    _addMetadataRow(details, 'Title', schema['title']);
    _addMetadataRow(details, 'Default', _scalarLabel(schema['default']));
    _addMetadataRow(details, 'Example', _scalarLabel(schema['example']));
    final required = _list(schema['required']).map(_string).toSet();
    if (required.isNotEmpty) {
      details.add(['Required properties', required.join(', ')]);
    }
    if (details.isNotEmpty) {
      blocks.add(_table(const ['Field', 'Value'], details));
    }
    final rows = <List<String>>[];
    for (final property in _map(schema['properties']).entries) {
      final propertySchema = _map(property.value);
      rows.add([
        property.key,
        _schemaLabel(propertySchema),
        required.contains(property.key) ? 'Yes' : 'No',
        _string(propertySchema['description']),
      ]);
    }
    if (rows.isNotEmpty) {
      blocks.add(
        _table(const ['Property', 'Type', 'Required', 'Description'], rows),
      );
    }
    return blocks;
  }

  void _addSecurityRequirement(
    List<MarkdownExportBlock> blocks,
    Object? value, {
    required int headingLevel,
  }) {
    final label = _securityLabel(value);
    if (label.isEmpty) {
      return;
    }
    blocks
      ..add(_heading(headingLevel, 'Security'))
      ..add(_paragraph(label));
  }

  String _securityLabel(Object? value) {
    final alternatives = <String>[];
    for (final requirement in _list(value).map(_map)) {
      final parts = <String>[];
      for (final entry in requirement.entries) {
        final scopes = _list(
          entry.value,
        ).map(_string).where((item) => item.isNotEmpty);
        parts.add(
          scopes.isEmpty ? entry.key : '${entry.key} (${scopes.join(', ')})',
        );
      }
      alternatives.add(parts.isEmpty ? 'No authentication' : parts.join(' + '));
    }
    return alternatives.join(' or ');
  }

  String _schemaLabel(Object? value) {
    final schema = _map(value);
    if (schema.isEmpty) {
      return '';
    }
    final reference = _string(schema[r'$ref']);
    if (reference.isNotEmpty) {
      return reference;
    }
    final declaredTypes = schema['type'] is List
        ? _list(
            schema['type'],
          ).map(_string).where((item) => item.isNotEmpty).toList()
        : [_string(schema['type'])].where((item) => item.isNotEmpty).toList();
    final type = declaredTypes.join(' | ');
    final format = _string(schema['format']);
    var label = type;
    if (declaredTypes.length == 1 && declaredTypes.single == 'array') {
      final item = _schemaLabel(schema['items']);
      label = item.isEmpty ? 'array' : 'array<$item>';
    }
    if (format.isNotEmpty) {
      label = label.isEmpty ? format : '$label ($format)';
    }
    for (final composition in const ['oneOf', 'anyOf', 'allOf']) {
      final members = _list(
        schema[composition],
      ).map(_schemaLabel).where((item) => item.isNotEmpty).join(', ');
      if (members.isNotEmpty) {
        label = '$composition<$members>';
        break;
      }
    }
    final values = _list(
      schema['enum'],
    ).map(_scalarLabel).where((item) => item.isNotEmpty);
    if (values.isNotEmpty) {
      final enumLabel = 'enum: ${values.join(', ')}';
      label = label.isEmpty ? enumLabel : '$label; $enumLabel';
    }
    return label;
  }

  MarkdownExportBlock _heading(int level, String text) => MarkdownExportBlock(
    kind: MarkdownExportBlockKind.heading,
    inlines: [_text(text)],
    attributes: {'level': level.clamp(1, 6)},
  );

  MarkdownExportBlock _paragraph(String text) => MarkdownExportBlock(
    kind: MarkdownExportBlockKind.paragraph,
    inlines: [_text(text)],
  );

  MarkdownExportBlock _table(List<String> headings, List<List<String>> rows) {
    MarkdownExportBlock row(List<String> values, {required bool header}) =>
        MarkdownExportBlock(
          kind: MarkdownExportBlockKind.tableRow,
          attributes: {'header': header},
          children: [
            for (final value in values)
              MarkdownExportBlock(
                kind: MarkdownExportBlockKind.tableCell,
                inlines: [_text(value)],
              ),
          ],
        );
    return MarkdownExportBlock(
      kind: MarkdownExportBlockKind.table,
      children: [
        row(headings, header: true),
        for (final values in rows) row(values, header: false),
      ],
    );
  }

  MarkdownExportInline _text(String value) =>
      MarkdownExportInline(kind: MarkdownExportInlineKind.text, text: value);

  void _addText(List<MarkdownExportBlock> blocks, String value) {
    if (value.trim().isNotEmpty) {
      blocks.add(_paragraph(value.trim()));
    }
  }

  void _addMetadataRow(List<List<String>> rows, String label, Object? value) {
    final text = _string(value);
    if (text.isNotEmpty) {
      rows.add([label, text]);
    }
  }

  Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<Object?> _list(Object? value) => value is List ? value : const [];

  String _string(Object? value) => value is String ? value.trim() : '';

  String _scalarLabel(Object? value) => switch (value) {
    String() => value,
    num() || bool() => value.toString(),
    _ => '',
  };

  String _firstNonEmpty(Iterable<String> values) =>
      values.firstWhere((value) => value.isNotEmpty, orElse: () => '');
}
