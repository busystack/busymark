import 'package:xml/xml.dart';

class MathSvgPreprocessing {
  const MathSvgPreprocessing({required this.svg, required this.depth});

  final String svg;
  final double depth;
}

class MathSvgPreprocessor {
  const MathSvgPreprocessor();

  static const _maximumStandaloneViewBoxDimension = 16000.0;

  MathSvgPreprocessing preprocess(
    String source, {
    required double ex,
    double? reportedDepth,
  }) {
    final document = XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local.toLowerCase() != 'svg') {
      throw const FormatException('MathJax output is not SVG.');
    }
    final declarations = _styleDeclarations(root.getAttribute('style') ?? '');
    final verticalAlign = declarations.remove('vertical-align');
    if (declarations.isEmpty) {
      root.removeAttribute('style');
    } else {
      root.setAttribute(
        'style',
        declarations.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .join(';'),
      );
    }
    _normalizeCoordinateRange(root);
    final extractedDepth = _depthFromVerticalAlign(verticalAlign, ex);
    return MathSvgPreprocessing(
      svg: document.toXmlString(pretty: false),
      depth: reportedDepth ?? extractedDepth,
    );
  }

  void _normalizeCoordinateRange(XmlElement root) {
    final values = root
        .getAttribute('viewBox')
        ?.trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList(growable: false);
    if (values == null ||
        values.length != 4 ||
        values.any((value) => value == null || !value.isFinite)) {
      return;
    }
    final width = values[2]!.abs();
    final height = values[3]!.abs();
    final scale = width > height
        ? width / _maximumStandaloneViewBoxDimension
        : height / _maximumStandaloneViewBoxDimension;
    if (scale <= 1) {
      return;
    }
    final originalChildren = root.children.toList(growable: false);
    root.children.clear();
    root.children.add(
      XmlElement(XmlName.parts('g'), [
        XmlAttribute(XmlName.parts('transform'), 'scale(${1 / scale})'),
      ], originalChildren),
    );
    root.setAttribute(
      'viewBox',
      values.map((value) => value! / scale).join(' '),
    );
  }

  String rebaseLocalIds(String source, String requestedPrefix) {
    final document = XmlDocument.parse(source);
    final prefix = requestedPrefix
        .replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), '-')
        .replaceFirst(RegExp(r'^[^A-Za-z_]'), 'm-');
    final ids = <String, String>{};
    var sequence = 0;
    for (final element in <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ]) {
      final oldId = element.getAttribute('id');
      if (oldId == null || oldId.isEmpty) {
        continue;
      }
      final replacement = '$prefix-${sequence++}';
      ids[oldId] = replacement;
      element.setAttribute('id', replacement);
    }
    if (ids.isEmpty) {
      return document.toXmlString(pretty: false);
    }
    for (final element in <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ]) {
      for (final attribute in element.attributes) {
        var value = attribute.value;
        for (final entry in ids.entries) {
          if (value == '#${entry.key}') {
            value = '#${entry.value}';
          }
          value = value.replaceAll(
            'url(#${entry.key})',
            'url(#${entry.value})',
          );
        }
        attribute.value = value;
      }
    }
    return document.toXmlString(pretty: false);
  }

  String resolveCurrentColor(String source, String color) {
    final document = XmlDocument.parse(source);
    final currentColor = RegExp(r'\bcurrentColor\b', caseSensitive: false);
    for (final element in <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ]) {
      for (final attribute in element.attributes) {
        attribute.value = attribute.value.replaceAll(currentColor, color);
      }
    }
    return document.toXmlString(pretty: false);
  }

  Map<String, String> _styleDeclarations(String source) {
    final result = <String, String>{};
    for (final declaration in source.split(';')) {
      final separator = declaration.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      result[declaration.substring(0, separator).trim().toLowerCase()] =
          declaration.substring(separator + 1).trim();
    }
    return result;
  }

  double _depthFromVerticalAlign(String? value, double ex) {
    if (value == null) {
      return 0;
    }
    final match = RegExp(
      r'^(-?(?:\d+(?:\.\d*)?|\.\d+))(ex|em|px)?$',
    ).firstMatch(value.trim());
    if (match == null) {
      return 0;
    }
    final amount = double.tryParse(match.group(1)!) ?? 0;
    final pixels = switch (match.group(2)) {
      'ex' => amount * ex,
      'em' => amount * ex * 2,
      _ => amount,
    };
    return pixels < 0 ? -pixels : 0;
  }
}
