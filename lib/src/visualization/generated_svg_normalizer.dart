import 'dart:convert';
import 'dart:math' as math;

import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css;
import 'package:xml/xml.dart';

class GeneratedSvgNormalization {
  const GeneratedSvgNormalization({
    required this.browserSafeSvg,
    required this.vectorSafeSvg,
    required this.width,
    required this.height,
    required this.hasForeignObject,
  });

  final String browserSafeSvg;
  final String? vectorSafeSvg;
  final double width;
  final double height;
  final bool hasForeignObject;
}

class GeneratedSvgException implements Exception {
  const GeneratedSvgException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class GeneratedSvgNormalizer {
  const GeneratedSvgNormalizer({
    this.maximumBytes = 16 * 1024 * 1024,
    this.maximumElements = 50000,
    this.maximumDimension = 20000,
  });

  final int maximumBytes;
  final int maximumElements;
  final double maximumDimension;

  GeneratedSvgNormalization normalize(String source) {
    if (utf8.encode(source).length > maximumBytes) {
      throw const GeneratedSvgException(
        'visualization.svgTooLarge',
        'Generated SVG exceeds the size limit.',
      );
    }
    final lowered = source.toLowerCase();
    if (lowered.contains('<!doctype') ||
        lowered.contains('<!entity') ||
        lowered.contains('<?xml-stylesheet') ||
        lowered.contains('@import')) {
      throw const GeneratedSvgException(
        'visualization.unsafeSvg',
        'Generated SVG contains a prohibited declaration.',
      );
    }

    late XmlDocument browserDocument;
    try {
      browserDocument = XmlDocument.parse(source);
    } on XmlParserException catch (error) {
      throw GeneratedSvgException('visualization.invalidSvg', error.message);
    }
    final root = browserDocument.rootElement;
    if (root.name.local.toLowerCase() != 'svg') {
      throw const GeneratedSvgException(
        'visualization.invalidSvg',
        'Generated output is not an SVG document.',
      );
    }
    final elements = <XmlElement>[
      root,
      ...root.descendants.whereType<XmlElement>(),
    ];
    if (elements.length > maximumElements) {
      throw const GeneratedSvgException(
        'visualization.svgTooComplex',
        'Generated SVG exceeds the element limit.',
      );
    }

    final hasForeignObject = elements.any(
      (element) => element.name.local.toLowerCase() == 'foreignobject',
    );
    _sanitizeDocument(browserDocument);
    final (width, height) = _dimensions(browserDocument.rootElement);
    final browserSafeSvg = browserDocument.toXmlString(pretty: false);

    String? vectorSafeSvg;
    if (!hasForeignObject) {
      final vectorDocument = XmlDocument.parse(browserSafeSvg);
      final stylesWereFullyInlined = _inlineStyleSheets(vectorDocument);
      if (stylesWereFullyInlined) {
        for (final style
            in vectorDocument
                .findAllElements('style')
                .toList(growable: false)) {
          style.parent?.children.remove(style);
        }
        if (vectorDocument.descendants.whereType<XmlElement>().any(
          (element) => element.name.local.toLowerCase() == 'foreignobject',
        )) {
          throw const GeneratedSvgException(
            'visualization.unsafeSvg',
            'Vector SVG normalization left browser-only content.',
          );
        }
        vectorSafeSvg = vectorDocument.toXmlString(pretty: false);
      }
    }

    return GeneratedSvgNormalization(
      browserSafeSvg: browserSafeSvg,
      vectorSafeSvg: vectorSafeSvg,
      width: width,
      height: height,
      hasForeignObject: hasForeignObject,
    );
  }

  void _sanitizeDocument(XmlDocument document) {
    const blockedElements = {
      'script',
      'iframe',
      'object',
      'embed',
      'audio',
      'video',
      'link',
      'meta',
      'canvas',
      'animate',
      'animatemotion',
      'animatetransform',
      'set',
      'discard',
    };
    final elements = <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ];
    for (final element in elements.reversed) {
      final elementName = element.name.local.toLowerCase();
      if (blockedElements.contains(elementName)) {
        element.parent?.children.remove(element);
        continue;
      }
      if (elementName == 'style') {
        final sanitized = _sanitizeStyleSheet(element.innerText);
        element.children
          ..clear()
          ..add(XmlCDATA(sanitized));
      }
      for (final attribute in element.attributes.toList(growable: false)) {
        final name = attribute.name.local.toLowerCase();
        final value = attribute.value.trim();
        if (name.startsWith('on') ||
            name == 'base' ||
            name == 'formaction' ||
            name == 'ping') {
          element.attributes.remove(attribute);
          continue;
        }
        if (name == 'style') {
          final safeStyle = _sanitizeBrowserInlineStyle(value);
          if (safeStyle.isEmpty) {
            element.attributes.remove(attribute);
          } else {
            attribute.value = safeStyle;
          }
          continue;
        }
        if ((name == 'href' || name == 'src') &&
            !_isSafeResourceReference(value)) {
          element.attributes.remove(attribute);
          continue;
        }
        if (_cssUrlAttributes.contains(name) && !_hasOnlySafeCssUrls(value)) {
          element.attributes.remove(attribute);
        }
      }
    }
  }

  String _sanitizeStyleSheet(String source) {
    final lowered = source.toLowerCase();
    if (lowered.contains('@import') ||
        lowered.contains('expression(') ||
        lowered.contains('javascript:')) {
      throw const GeneratedSvgException(
        'visualization.unsafeSvgCss',
        'Generated SVG CSS contains an external or executable reference.',
      );
    }
    final errors = <css_parser.Message>[];
    final sheet = css_parser.parse(source, errors: errors);
    if (errors.any((error) => error.level == css_parser.MessageLevel.severe)) {
      throw const GeneratedSvgException(
        'visualization.invalidSvgCss',
        'Generated SVG contains invalid CSS.',
      );
    }
    final uriValidator = _CssUriValidator(
      allowDataFonts: true,
      allowDataImages: true,
    );
    sheet.visit(uriValidator);
    if (!uriValidator.safe) {
      throw const GeneratedSvgException(
        'visualization.unsafeSvgCss',
        'Generated SVG CSS contains an external or executable reference.',
      );
    }
    sheet.topLevels.removeWhere((node) => node is css.KeyFrameDirective);
    sheet.visit(_CssAnimationRemovingVisitor());
    final printer = css.CssPrinter()..visitTree(sheet);
    return printer.toString();
  }

  bool _inlineStyleSheets(XmlDocument document) {
    final appliedProperties = <XmlElement, Map<String, String>>{};
    var complete = _inlineStylesAreVectorRepresentable(document);
    final styleElements = document.findAllElements('style').toList();
    for (final styleElement in styleElements) {
      final errors = <css_parser.Message>[];
      final sheet = css_parser.parse(styleElement.innerText, errors: errors);
      if (errors.any(
        (error) => error.level == css_parser.MessageLevel.severe,
      )) {
        throw const GeneratedSvgException(
          'visualization.invalidSvgCss',
          'Generated SVG contains invalid CSS.',
        );
      }
      if (!_applyRules(document, sheet.topLevels, appliedProperties)) {
        complete = false;
      }
    }
    return complete;
  }

  bool _inlineStylesAreVectorRepresentable(XmlDocument document) {
    for (final element in <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ]) {
      final source = element.getAttribute('style');
      if (source == null || source.isEmpty) {
        continue;
      }
      final errors = <css_parser.Message>[];
      final sheet = css_parser.parse('x{$source}', errors: errors);
      if (errors.any(
            (error) => error.level == css_parser.MessageLevel.severe,
          ) ||
          sheet.topLevels.isEmpty ||
          sheet.topLevels.first is! css.RuleSet) {
        return false;
      }
      final rule = sheet.topLevels.first as css.RuleSet;
      for (final item in rule.declarationGroup.declarations) {
        if (item is! css.Declaration ||
            item.expression == null ||
            !_isSafePresentation(
              item.property.toLowerCase(),
              _serializeExpression(item.expression!),
            )) {
          return false;
        }
      }
    }
    return true;
  }

  bool _applyRules(
    XmlDocument document,
    Iterable<css.TreeNode> nodes,
    Map<XmlElement, Map<String, String>> appliedProperties,
  ) {
    var complete = true;
    final elements = <XmlElement>[
      document.rootElement,
      ...document.rootElement.descendants.whereType<XmlElement>(),
    ];
    for (final node in nodes) {
      // Conditional rules, embedded fonts, and other at-rules cannot be
      // represented by SVG presentation attributes without changing their
      // browser semantics. Keep the sanitized browser SVG and rasterize it.
      if (node is! css.RuleSet || node.selectorGroup == null) {
        complete = false;
        continue;
      }
      final declarations = <String, String>{};
      var hasUnrepresentableDeclaration = false;
      for (final item in node.declarationGroup.declarations) {
        if (item is! css.Declaration || item.expression == null) {
          hasUnrepresentableDeclaration = true;
          continue;
        }
        final property = item.property.toLowerCase();
        final value = _serializeExpression(item.expression!);
        if (!item.important && _isSafePresentation(property, value)) {
          declarations[property] = value;
        } else {
          hasUnrepresentableDeclaration = true;
        }
      }
      for (final selector in node.selectorGroup!.selectors) {
        final selectorSource = selector.span?.text.trim() ?? '';
        if (!_isSupportedSelector(selectorSource)) {
          if (node.declarationGroup.declarations.isNotEmpty) {
            complete = false;
          }
          continue;
        }
        final matches = elements.where(
          (element) => _matchesSelector(element, selectorSource),
        );
        for (final element in matches) {
          if (hasUnrepresentableDeclaration) {
            complete = false;
          }
          final inlineProperties = _inlineStyleProperties(element);
          final applied = appliedProperties.putIfAbsent(element, () => {});
          for (final entry in declarations.entries) {
            // Normal stylesheet declarations do not override inline style.
            if (inlineProperties.contains(entry.key)) {
              continue;
            }
            final previous = applied[entry.key];
            if (previous != null && previous != entry.value) {
              // Resolving the full CSS cascade is outside this conservative
              // inliner. Rasterization preserves the browser's exact result.
              complete = false;
              continue;
            }
            applied[entry.key] = entry.value;
            if (entry.key == 'display') {
              final existing = element.getAttribute('style') ?? '';
              element.setAttribute(
                'style',
                _mergeInlineDeclaration(existing, entry.key, entry.value),
              );
            } else {
              element.setAttribute(entry.key, entry.value);
            }
          }
        }
      }
    }
    return complete;
  }

  Set<String> _inlineStyleProperties(XmlElement element) {
    final style = element.getAttribute('style');
    if (style == null || style.isEmpty) {
      return const {};
    }
    return {
      for (final declaration in style.split(';'))
        if (declaration.indexOf(':') case final separator when separator > 0)
          declaration.substring(0, separator).trim().toLowerCase(),
    };
  }

  String _sanitizeBrowserInlineStyle(String source) {
    final errors = <css_parser.Message>[];
    final sheet = css_parser.parse('x{$source}', errors: errors);
    if (errors.any((error) => error.level == css_parser.MessageLevel.severe) ||
        sheet.topLevels.isEmpty ||
        sheet.topLevels.first is! css.RuleSet) {
      return '';
    }
    final rule = sheet.topLevels.first as css.RuleSet;
    final declarations = <String>[];
    for (final item in rule.declarationGroup.declarations) {
      if (item is! css.Declaration || item.expression == null) {
        continue;
      }
      final property = item.property.toLowerCase();
      final value = _serializeExpression(item.expression!);
      if (_isSafeBrowserPresentation(property, value)) {
        declarations.add(
          '$property:$value${item.important ? '!important' : ''}',
        );
      }
    }
    return declarations.join(';');
  }

  bool _isSafeBrowserPresentation(String property, String value) {
    const blockedProperties = {
      'behavior',
      '-moz-binding',
      ..._CssAnimationRemovingVisitor.blockedProperties,
    };
    final lowered = value.toLowerCase();
    return property.isNotEmpty &&
        property.length <= 128 &&
        value.length <= 4096 &&
        !blockedProperties.contains(property) &&
        !lowered.contains('expression(') &&
        !lowered.contains('javascript:') &&
        _hasOnlySafeCssUrls(value, allowDataImages: true);
  }

  String _safeInlineStyle(String source) {
    final errors = <css_parser.Message>[];
    final sheet = css_parser.parse('x{$source}', errors: errors);
    if (errors.any((error) => error.level == css_parser.MessageLevel.severe) ||
        sheet.topLevels.isEmpty ||
        sheet.topLevels.first is! css.RuleSet) {
      return '';
    }
    final rule = sheet.topLevels.first as css.RuleSet;
    final declarations = <String>[];
    for (final item in rule.declarationGroup.declarations) {
      if (item is! css.Declaration || item.expression == null) {
        continue;
      }
      final property = item.property.toLowerCase();
      final value = _serializeExpression(item.expression!);
      if (_isSafePresentation(property, value)) {
        declarations.add('$property:$value');
      }
    }
    return declarations.join(';');
  }

  bool _isSafePresentation(String property, String value) {
    const properties = {
      'fill',
      'fill-opacity',
      'stroke',
      'stroke-width',
      'stroke-opacity',
      'stroke-dasharray',
      'stroke-dashoffset',
      'stroke-linecap',
      'stroke-linejoin',
      'opacity',
      'color',
      'font-family',
      'font-size',
      'font-style',
      'font-weight',
      'text-anchor',
      'dominant-baseline',
      'shape-rendering',
      'display',
      'visibility',
      'paint-order',
    };
    if (!properties.contains(property)) {
      return false;
    }
    final lowered = value.toLowerCase();
    return value.length <= 512 &&
        !lowered.contains('expression(') &&
        !lowered.contains('javascript:') &&
        !lowered.contains('var(') &&
        _hasOnlySafeCssUrls(value);
  }

  String _serializeExpression(css.Expression expression) {
    final printer = css.CssPrinter();
    expression.visit(printer);
    return printer.toString().trim();
  }

  bool _isSafeResourceReference(String value) {
    final lowered = value.toLowerCase();
    return value.isEmpty ||
        value.startsWith('#') ||
        lowered.startsWith('data:image/png;base64,') ||
        lowered.startsWith('data:image/jpeg;base64,') ||
        lowered.startsWith('data:image/gif;base64,') ||
        lowered.startsWith('data:image/webp;base64,');
  }

  bool _hasOnlySafeCssUrls(
    String value, {
    bool allowDataFonts = false,
    bool allowDataImages = false,
  }) {
    final errors = <css_parser.Message>[];
    final sheet = css_parser.parse('x{fill:$value}', errors: errors);
    if (errors.any((error) => error.level == css_parser.MessageLevel.severe)) {
      return false;
    }
    final validator = _CssUriValidator(
      allowDataFonts: allowDataFonts,
      allowDataImages: allowDataImages,
    );
    sheet.visit(validator);
    return validator.safe;
  }

  bool _isSupportedSelector(String selector) {
    return selector.isNotEmpty &&
        selector.length <= 256 &&
        RegExp(
          r'^[A-Za-z_.#][A-Za-z0-9_.#-]*(?:\s+[A-Za-z_.#][A-Za-z0-9_.#-]*)*$',
        ).hasMatch(selector);
  }

  bool _matchesSelector(XmlElement element, String selector) {
    final compounds = selector.split(RegExp(r'\s+'));
    if (!_matchesCompound(element, compounds.last)) {
      return false;
    }
    XmlElement? ancestor = element.parentElement;
    for (var index = compounds.length - 2; index >= 0; index--) {
      while (ancestor != null &&
          !_matchesCompound(ancestor, compounds[index])) {
        ancestor = ancestor.parentElement;
      }
      if (ancestor == null) {
        return false;
      }
      ancestor = ancestor.parentElement;
    }
    return true;
  }

  bool _matchesCompound(XmlElement element, String compound) {
    final idIndex = compound.indexOf('#');
    final classIndex = compound.indexOf('.');
    final nameEnd = [
      if (idIndex >= 0) idIndex,
      if (classIndex >= 0) classIndex,
      compound.length,
    ].reduce(math.min);
    final elementName = compound.substring(0, nameEnd);
    if (elementName.isNotEmpty &&
        element.name.local.toLowerCase() != elementName.toLowerCase()) {
      return false;
    }
    final idMatch = RegExp(r'#([A-Za-z_][A-Za-z0-9_-]*)').firstMatch(compound);
    if (idMatch != null && element.getAttribute('id') != idMatch.group(1)) {
      return false;
    }
    final classes = (element.getAttribute('class') ?? '')
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toSet();
    for (final match in RegExp(
      r'\.([A-Za-z_][A-Za-z0-9_-]*)',
    ).allMatches(compound)) {
      if (!classes.contains(match.group(1))) {
        return false;
      }
    }
    return true;
  }

  String _mergeInlineDeclaration(
    String existing,
    String property,
    String value,
  ) {
    final safeExisting = _safeInlineStyle(existing);
    if (safeExisting.split(';').any((item) => item.startsWith('$property:'))) {
      return safeExisting;
    }
    return [
      safeExisting,
      '$property:$value',
    ].where((item) => item.isNotEmpty).join(';');
  }

  (double, double) _dimensions(XmlElement root) {
    final viewBox = root
        .getAttribute('viewBox')
        ?.trim()
        .split(RegExp(r'[\s,]+'));
    double? width;
    double? height;
    if (viewBox != null && viewBox.length == 4) {
      width = double.tryParse(viewBox[2]);
      height = double.tryParse(viewBox[3]);
    }
    width ??= _numericDimension(root.getAttribute('width'));
    height ??= _numericDimension(root.getAttribute('height'));
    width ??= 1;
    height ??= 1;
    if (!width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        width > maximumDimension ||
        height > maximumDimension) {
      throw const GeneratedSvgException(
        'visualization.invalidSvgDimensions',
        'Generated SVG dimensions are invalid or exceed the limit.',
      );
    }
    return (width, height);
  }

  double? _numericDimension(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(
      value.trim().replaceFirst(RegExp(r'(?:px|pt)$'), ''),
    );
  }
}

const _cssUrlAttributes = {
  'background',
  'clip-path',
  'color-profile',
  'cursor',
  'fill',
  'filter',
  'marker',
  'marker-end',
  'marker-mid',
  'marker-start',
  'mask',
  'stroke',
};

class _CssUriValidator extends css.Visitor {
  _CssUriValidator({
    required this.allowDataFonts,
    this.allowDataImages = false,
  });

  final bool allowDataFonts;
  final bool allowDataImages;
  var safe = true;

  @override
  void visitUriTerm(css.UriTerm node) {
    final target = node.value.toString().trim();
    final lowered = target.toLowerCase();
    if (target.startsWith('#')) {
      return;
    }
    if (allowDataFonts &&
        (lowered.startsWith('data:application/font-woff;base64,') ||
            lowered.startsWith('data:font/woff;base64,') ||
            lowered.startsWith('data:font/woff2;base64,'))) {
      return;
    }
    if (allowDataImages &&
        (lowered.startsWith('data:image/png;base64,') ||
            lowered.startsWith('data:image/jpeg;base64,') ||
            lowered.startsWith('data:image/gif;base64,') ||
            lowered.startsWith('data:image/webp;base64,'))) {
      return;
    }
    safe = false;
  }
}

class _CssAnimationRemovingVisitor extends css.Visitor {
  static const blockedProperties = {
    'animation',
    'animation-delay',
    'animation-direction',
    'animation-duration',
    'animation-fill-mode',
    'animation-iteration-count',
    'animation-name',
    'animation-play-state',
    'animation-timing-function',
    'transition',
    'transition-delay',
    'transition-duration',
    'transition-property',
    'transition-timing-function',
  };

  @override
  void visitDeclarationGroup(css.DeclarationGroup node) {
    node.declarations.removeWhere(
      (item) =>
          item is css.Declaration &&
          blockedProperties.contains(item.property.toLowerCase()),
    );
    super.visitDeclarationGroup(node);
  }
}
