import 'writerside_code_selection.dart';
import 'writerside_schema.dart';

/// Scalar validation shares schema rules and the existing snippet selector.
/// An unavailable source prevents range verification, not legal authoring.
String? validateWritersideProperty(
  String tag,
  String attribute,
  String? value, {
  Map<String, String> attributes = const {},
  String? codeSource,
  String? inlineCode,
  bool hasTitleChild = false,
}) {
  final name = attribute == 'language' ? 'lang' : attribute;
  if (!WritersideSchema.attributesFor(tag).contains(name)) {
    return 'unsupported attribute: $name';
  }
  if (value == null || value.isEmpty && name != 'alt') {
    return WritersideSchema.requiredAttributesFor(tag).contains(name) &&
            !(name == 'title' && hasTitleChild)
        ? 'required attribute: $name'
        : null;
  }
  final invalid = WritersideSchema.invalidAttributeValue(tag, name, value);
  if (invalid != null) return '$name: $invalid';
  if (value.contains('%')) return null;
  if (tag == 'code-block' &&
      name == 'src' &&
      value != attributes['src'] &&
      inlineCode?.trim().isNotEmpty == true) {
    return 'src: the authored code block is nonempty; preserve it or clear it explicitly in the editor before selecting a source file';
  }
  if (name == 'id' && !RegExp(r'^[A-Za-z_][A-Za-z0-9_.-]*$').hasMatch(value)) {
    return 'id: expected an identifier starting with a letter or underscore';
  }
  if (tag == 'code-block' &&
      {'include-lines', 'emphasize-lines'}.contains(name)) {
    for (final part in value.split(',')) {
      final match = RegExp(r'^\s*(\d+)(?:\s*-\s*(\d+))?\s*$').firstMatch(part);
      if (match == null ||
          int.parse(match[1]!) < 1 ||
          int.parse(match[2] ?? match[1]!) < int.parse(match[1]!)) {
        return '$name: expected positive lines or ascending ranges';
      }
    }
    if (name == 'include-lines' &&
        attributes['include-symbol']?.isNotEmpty == true) {
      return 'include-lines conflicts with include-symbol';
    }
    if (codeSource != null) {
      try {
        final snippet = name == 'emphasize-lines'
            ? const WritersideCodeSelection().select(codeSource, attributes)
            : codeSource;
        const WritersideCodeSelection().select(snippet, {
          'include-lines': value,
        });
      } on FormatException catch (e) {
        return '$name: ${e.message}';
      }
    }
  }
  if (tag == 'code-block' &&
      name == 'include-symbol' &&
      attributes['include-lines']?.isNotEmpty == true) {
    return 'include-symbol conflicts with include-lines';
  }
  if (tag == 'code-block' && name == 'include-symbol' && codeSource != null) {
    try {
      const WritersideCodeSelection().select(codeSource, {
        ...attributes,
        name: value,
      });
    } on FormatException catch (e) {
      return '$name: ${e.message}';
    }
  }
  return null;
}
