import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'writerside_pdf_models.dart';

class WritersidePdfConfigurationCodec {
  const WritersidePdfConfigurationCodec();

  String encode(WritersidePdfOptions options, {String? containerLogoPath}) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'pdf',
      attributes: {
        'landscape': options.orientation.name == 'landscape' ? 'true' : 'false',
      },
      nest: () {
        final cover = options.cover;
        if (cover.enabled) {
          builder.element(
            'cover-page',
            nest: () {
              _textElement(builder, 'title', cover.title);
              _textElement(builder, 'logo', containerLogoPath ?? '');
              _textElement(builder, 'description', cover.description);
              _textElement(builder, 'copyright', cover.copyright);
            },
          );
        }
        _textElement(builder, 'header', options.header);
        _textElement(builder, 'footer', options.footer);
        _textElement(builder, 'toc-title', options.tocTitle);
        _textElement(builder, 'layout', options.layout);
      },
    );
    return '${builder.buildDocument().toXmlString(pretty: true)}\n';
  }

  bool isPdfConfiguration(String source) {
    try {
      return XmlDocument.parse(source).rootElement.name.local == 'pdf';
    } on XmlException {
      return false;
    }
  }

  Future<List<String>> discover({
    required String moduleRoot,
    required String buildConfigDirectory,
    int maximumFileBytes = 1024 * 1024,
  }) async {
    final directory = Directory(
      p.normalize(p.join(moduleRoot, buildConfigDirectory)),
    );
    if (!await directory.exists()) {
      return const [];
    }
    final result = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.xml') {
        continue;
      }
      try {
        if (await entity.length() > maximumFileBytes) {
          continue;
        }
        if (isPdfConfiguration(await entity.readAsString())) {
          result.add(p.normalize(p.absolute(entity.path)));
        }
      } on FileSystemException {
        // A concurrently removed or unreadable candidate is not selectable.
      }
    }
    result.sort((left, right) => p.basename(left).compareTo(p.basename(right)));
    return List.unmodifiable(result);
  }

  Future<List<WritersidePdfKeymapLayout>> discoverLayouts({
    required String moduleRoot,
    required String buildConfigDirectory,
    required String instanceId,
    int maximumFileBytes = 4 * 1024 * 1024,
  }) async {
    final file = File(
      p.normalize(
        p.join(moduleRoot, buildConfigDirectory, 'buildprofiles.xml'),
      ),
    );
    try {
      if (!await file.exists() || await file.length() > maximumFileBytes) {
        return const [];
      }
      final document = XmlDocument.parse(await file.readAsString());
      if (document.rootElement.name.local != 'buildprofiles') {
        return const [];
      }
      final layouts = <String, WritersidePdfKeymapLayout>{};
      for (final shortcuts in document.descendants.whereType<XmlElement>()) {
        if (shortcuts.name.local != 'shortcuts' ||
            !_appliesToInstance(
              shortcuts.getAttribute('instance'),
              instanceId,
            )) {
          continue;
        }
        for (final layout in shortcuts.childElements.where(
          (element) => element.name.local == 'layout',
        )) {
          if (!_appliesToInstance(
            layout.getAttribute('instance'),
            instanceId,
          )) {
            continue;
          }
          final name = layout.getAttribute('name')?.trim() ?? '';
          if (name.isEmpty) {
            continue;
          }
          layouts[name] = WritersidePdfKeymapLayout(
            name: name,
            displayName:
                layout.getAttribute('display-name')?.trim().isNotEmpty == true
                ? layout.getAttribute('display-name')!.trim()
                : name,
          );
        }
      }
      return List.unmodifiable(layouts.values);
    } on FileSystemException {
      return const [];
    } on XmlException {
      return const [];
    }
  }

  void _textElement(XmlBuilder builder, String name, String value) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      builder.element(name, nest: normalized);
    }
  }

  bool _appliesToInstance(String? condition, String instanceId) {
    final normalized = condition?.trim();
    if (normalized == null || normalized.isEmpty) {
      return true;
    }
    final values = normalized
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return values.contains(instanceId);
  }
}
