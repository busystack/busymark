import 'writerside_model.dart';

enum WritersidePropertyOrigin {
  element,
  ancestor,
  module,
  markdownMarker,
  builtIn,
  unresolved,
}

class WritersideEffectiveProperty {
  const WritersideEffectiveProperty(
    this.authored,
    this.value,
    this.origin, {
    this.limitation,
  });
  final String? authored;
  final String? value;
  final WritersidePropertyOrigin origin;

  /// A verified builder limitation, independent of the resolved value.
  final String? limitation;
  bool get unresolved => value == null;
}

/// Rules are tied to the supported builder. State-only forms are retained,
/// but 2026.08.0328 requires effective collapsible=true for published collapse.
class WritersideEffectiveProperties {
  const WritersideEffectiveProperties({
    this.settings = const WritersideSettingsConfig(),
    this.variables = const {},
    this.resolvedValues = const {},
    this.inheritedIgnoreVars,
  });
  final WritersideSettingsConfig settings;
  final Map<String, String> variables;

  /// Values from the existing document resolver for this authored occurrence.
  final Map<String, String> resolvedValues;
  final String? inheritedIgnoreVars;

  WritersideEffectiveProperty resolve(
    String element,
    String property,
    Map<String, String> attributes, {
    Map<String, String>? definitionList,
  }) {
    final authored = attributes[property];
    // The supported builder accepts module <caps> declarations but leaves
    // heading/TOC text unchanged. Local caps and default-property are applied.
    // Keep this distinction explicit instead of calling an omitted caps value
    // unresolved or promising the documented module rule's ignored effect.
    final capsLimitation =
        property == 'caps' &&
            authored == null &&
            settings.capsRules.any((r) => r.target == element)
        ? 'module-caps-ignored'
        : null;
    String? value = authored;
    var origin = WritersidePropertyOrigin.element;
    if (value == null &&
        element == 'list' &&
        property == 'type' &&
        attributes['busymark-native-list-type'] == 'decimal') {
      value = 'decimal';
      origin = WritersidePropertyOrigin.markdownMarker;
    }
    if (value == null &&
        element == 'list' &&
        property == 'start' &&
        attributes['busymark-native-list-start'] != null &&
        attributes['busymark-native-list-start'] != '1') {
      value = attributes['busymark-native-list-start'];
      origin = WritersidePropertyOrigin.markdownMarker;
    }
    final inherited =
        element == 'def' &&
        property == 'default-state' &&
        authored == 'inherited';
    if (element == 'def' && property == 'collapsible') {
      value = definitionList?['collapsible'] ?? 'false';
      origin = definitionList == null
          ? WritersidePropertyOrigin.builtIn
          : WritersidePropertyOrigin.ancestor;
    } else if (inherited) {
      value = definitionList?['default-state'];
      origin = WritersidePropertyOrigin.ancestor;
    } else if (value == null) {
      final defaults = settings.defaultProperties
          .where(
            (p) =>
                p.elementName == element &&
                p.propertyName == property &&
                p.value != null,
          )
          .toList();
      if (defaults.length == 1 || defaults.isNotEmpty && property == 'caps') {
        // Capitalization default-property uses the first declaration in the
        // pinned builder, independently of ignored module <caps> rules.
        value = defaults.first.value;
        origin = WritersidePropertyOrigin.module;
      }
      if (defaults.length > 1 && property != 'caps') {
        return WritersideEffectiveProperty(
          authored,
          null,
          WritersidePropertyOrigin.unresolved,
        );
      }
    }
    if (value == null && element == 'def' && property == 'default-state') {
      value = definitionList?['default-state'];
      origin = WritersidePropertyOrigin.ancestor;
    }
    if (value == null &&
        property == 'ignore-vars' &&
        inheritedIgnoreVars != null) {
      value = inheritedIgnoreVars;
      origin = WritersidePropertyOrigin.ancestor;
    }
    if (value == null) {
      value = switch (property) {
        'collapsible' =>
          element == 'def'
              ? (definitionList?['collapsible'] ?? 'false')
              : 'false',
        'default-state' => 'collapsed',
        'ignore-vars' =>
          settings.smartIgnoreVars == true &&
                  (element == 'code-block' ||
                      {'img', 'a'}.contains(element) &&
                          RegExp(r'^(?:https?:)?//').hasMatch(
                            attributes[element == 'img' ? 'src' : 'href'] ?? '',
                          ))
              ? 'true'
              : 'false',
        'type' when element == 'deflist' => 'full',
        'caps' => 'aswritten',
        'type' when element == 'list' =>
          attributes['busymark-native-list-type'] ?? 'bullet',
        'sorted' when element == 'list' => 'none',
        'start' when element == 'list' => '1',
        _ => null,
      };
      origin =
          element == 'def' &&
              property == 'collapsible' &&
              definitionList?.containsKey('collapsible') == true
          ? WritersidePropertyOrigin.ancestor
          : WritersidePropertyOrigin.builtIn;
    }
    var unresolved = false;
    if (value?.contains('%') == true && resolvedValues.containsKey(property)) {
      value = resolvedValues[property];
    }
    value = value?.replaceAllMapped(RegExp(r'%([^%]+)%'), (match) {
      final replacement = variables[match[1]];
      if (replacement == null) unresolved = true;
      return replacement ?? match[0]!;
    });
    return WritersideEffectiveProperty(
      authored,
      unresolved ? null : value,
      unresolved ? WritersidePropertyOrigin.unresolved : origin,
      limitation: capsLimitation,
    );
  }

  Map<String, String> defaultsFor(
    String element,
    Map<String, String> authored,
  ) => {
    for (final p in settings.defaultProperties)
      if (p.elementName == element && p.propertyName != null && p.value != null)
        p.propertyName!: p.value!,
    ...authored,
  };
}
