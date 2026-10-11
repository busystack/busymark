import 'writerside_model.dart';

enum WritersidePropertyOrigin { element, ancestor, module, builtIn, unresolved }

class WritersideEffectiveProperty {
  const WritersideEffectiveProperty(this.authored, this.value, this.origin);
  final String? authored;
  final String? value;
  final WritersidePropertyOrigin origin;
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
    String? value = authored;
    var origin = WritersidePropertyOrigin.element;
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
      if (defaults.length == 1) {
        value = defaults.single.value;
        origin = WritersidePropertyOrigin.module;
      }
      if (defaults.length > 1) {
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
