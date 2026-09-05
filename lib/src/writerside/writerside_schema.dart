import 'writerside_schema_data.dart';

enum WritersideAttributeReferenceKind {
  topic,
  element,
  variable,
  instance,
  resource,
  apiSpecification,
  image,
  category,
  module,
}

/// Writerside builder version against which BusyMark's semantic capabilities
/// are defined and tested.
const writersideDefaultBuilderVersion = '2026.08.0328';

enum WritersideSemanticKind {
  topic,
  paragraph,
  chapter,
  title,
  list,
  listItem,
  table,
  tableRow,
  tableCell,
  link,
  image,
  video,
  procedure,
  step,
  codeBlock,
  math,
  note,
  tip,
  warning,
  quote,
  tabs,
  tab,
  definitionList,
  definition,
  control,
  path,
  shortcut,
  code,
  resource,
  tooltip,
  strong,
  emphasis,
  include,
  snippet,
  condition,
  variable,
  lineBreak,
  metadata,
  container,
  startingPage,
  section,
  card,
  seealso,
  category,
  api,
}

class WritersideElementCapability {
  const WritersideElementCapability({
    required this.name,
    required this.kind,
    this.attributes = const {},
    this.requiredAttributes = const {},
    this.parents = const {},
    this.block = true,
    this.rendered = true,
  });

  final String name;
  final WritersideSemanticKind kind;
  final Set<String> attributes;
  final Set<String> requiredAttributes;
  final Set<String> parents;
  final bool block;
  final bool rendered;
}

/// A versioned, centralized capability view of the official Writerside schema.
///
/// It intentionally distinguishes schema-known elements from elements for
/// which BusyMark has a dedicated rendering semantic. Schema-known elements
/// without a special renderer remain lossless generic nodes.
class WritersideSchema {
  const WritersideSchema._();

  static const builderVersion = writersideDefaultBuilderVersion;

  // These names are also ordinary HTML. In a Writerside Markdown file they
  // must continue through the Markdown HTML pipeline unless a surrounding
  // Writerside-only element establishes semantic-markup context.
  static const _htmlCompatibleElements = {
    'a',
    'br',
    'em',
    'img',
    'p',
    'strong',
    'table',
    'td',
    'tr',
  };

  static const commonConditionalAttributes = {
    'filter',
    'id',
    'ignore-vars',
    'instance',
    'switcher-key',
  };

  static const elements = <String, WritersideElementCapability>{
    'topic': WritersideElementCapability(
      name: 'topic',
      kind: WritersideSemanticKind.topic,
      attributes: {
        ...commonConditionalAttributes,
        'title',
        'switcher-label',
        'is-library',
      },
      requiredAttributes: {'id'},
    ),
    'p': WritersideElementCapability(
      name: 'p',
      kind: WritersideSemanticKind.paragraph,
      attributes: commonConditionalAttributes,
    ),
    'chapter': WritersideElementCapability(
      name: 'chapter',
      kind: WritersideSemanticKind.chapter,
      attributes: {
        ...commonConditionalAttributes,
        'caps',
        'collapsible',
        'default-state',
        'help-id',
        'level',
        'title',
      },
      requiredAttributes: {'title'},
    ),
    'title': WritersideElementCapability(
      name: 'title',
      kind: WritersideSemanticKind.title,
      attributes: {'filter', 'instance'},
      rendered: false,
    ),
    'list': WritersideElementCapability(
      name: 'list',
      kind: WritersideSemanticKind.list,
      attributes: {...commonConditionalAttributes, 'columns', 'type'},
    ),
    'li': WritersideElementCapability(
      name: 'li',
      kind: WritersideSemanticKind.listItem,
      attributes: {...commonConditionalAttributes, 'checked'},
      parents: {'list'},
    ),
    'table': WritersideElementCapability(
      name: 'table',
      kind: WritersideSemanticKind.table,
      attributes: {
        ...commonConditionalAttributes,
        'column-width',
        'style',
        'sticky-header',
        'sortable',
      },
    ),
    'tr': WritersideElementCapability(
      name: 'tr',
      kind: WritersideSemanticKind.tableRow,
      attributes: commonConditionalAttributes,
      parents: {'table'},
    ),
    'td': WritersideElementCapability(
      name: 'td',
      kind: WritersideSemanticKind.tableCell,
      attributes: {
        ...commonConditionalAttributes,
        'align',
        'colspan',
        'rowspan',
        'width',
        'sortable',
      },
      parents: {'tr'},
    ),
    'a': WritersideElementCapability(
      name: 'a',
      kind: WritersideSemanticKind.link,
      attributes: {
        ...commonConditionalAttributes,
        'anchor',
        'as',
        'nullable',
        'href',
        'origin',
        'summary',
      },
      block: false,
    ),
    'img': WritersideElementCapability(
      name: 'img',
      kind: WritersideSemanticKind.image,
      attributes: {
        ...commonConditionalAttributes,
        'alt',
        'border-effect',
        'dark-src',
        'height',
        'origin',
        'preview-src',
        'scale',
        'src',
        'style',
        'theme',
        'thumbnail',
        'width',
      },
      requiredAttributes: {'src'},
      block: false,
    ),
    'video': WritersideElementCapability(
      name: 'video',
      kind: WritersideSemanticKind.video,
      attributes: {
        ...commonConditionalAttributes,
        'border-effect',
        'height',
        'mini-player',
        'origin',
        'preview-src',
        'src',
        'width',
      },
      requiredAttributes: {'src'},
    ),
    'procedure': WritersideElementCapability(
      name: 'procedure',
      kind: WritersideSemanticKind.procedure,
      attributes: {
        ...commonConditionalAttributes,
        'collapsible',
        'default-state',
        'title',
      },
    ),
    'step': WritersideElementCapability(
      name: 'step',
      kind: WritersideSemanticKind.step,
      attributes: commonConditionalAttributes,
      parents: {'procedure'},
    ),
    'code-block': WritersideElementCapability(
      name: 'code-block',
      kind: WritersideSemanticKind.codeBlock,
      attributes: {
        ...commonConditionalAttributes,
        'collapsed-title',
        'collapsed-title-line-number',
        'collapsible',
        'default-state',
        'disable-links',
        'emphasize-lines',
        'include-lines',
        'include-symbol',
        'lang',
        'noinject',
        'prompt',
        'show-white-spaces',
        'src',
        'validate',
      },
    ),
    'math': WritersideElementCapability(
      name: 'math',
      kind: WritersideSemanticKind.math,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'note': WritersideElementCapability(
      name: 'note',
      kind: WritersideSemanticKind.note,
      attributes: {...commonConditionalAttributes, 'title'},
    ),
    'tip': WritersideElementCapability(
      name: 'tip',
      kind: WritersideSemanticKind.tip,
      attributes: {...commonConditionalAttributes, 'title'},
    ),
    'warning': WritersideElementCapability(
      name: 'warning',
      kind: WritersideSemanticKind.warning,
      attributes: {...commonConditionalAttributes, 'title'},
    ),
    'quote': WritersideElementCapability(
      name: 'quote',
      kind: WritersideSemanticKind.quote,
      attributes: {...commonConditionalAttributes, 'author'},
    ),
    'tabs': WritersideElementCapability(
      name: 'tabs',
      kind: WritersideSemanticKind.tabs,
      attributes: {...commonConditionalAttributes, 'group'},
    ),
    'tab': WritersideElementCapability(
      name: 'tab',
      kind: WritersideSemanticKind.tab,
      attributes: {...commonConditionalAttributes, 'title', 'group-key'},
      requiredAttributes: {'title'},
      parents: {'tabs'},
    ),
    'deflist': WritersideElementCapability(
      name: 'deflist',
      kind: WritersideSemanticKind.definitionList,
      attributes: {
        ...commonConditionalAttributes,
        'collapsible',
        'default-state',
        'sorted',
        'style',
        'type',
      },
    ),
    'def': WritersideElementCapability(
      name: 'def',
      kind: WritersideSemanticKind.definition,
      attributes: {
        ...commonConditionalAttributes,
        'collapsible',
        'default-state',
        'title',
      },
      requiredAttributes: {'title'},
      parents: {'deflist'},
    ),
    'control': WritersideElementCapability(
      name: 'control',
      kind: WritersideSemanticKind.control,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'path': WritersideElementCapability(
      name: 'path',
      kind: WritersideSemanticKind.path,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'shortcut': WritersideElementCapability(
      name: 'shortcut',
      kind: WritersideSemanticKind.shortcut,
      attributes: {...commonConditionalAttributes, 'key'},
      block: false,
    ),
    'code': WritersideElementCapability(
      name: 'code',
      kind: WritersideSemanticKind.code,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'resource': WritersideElementCapability(
      name: 'resource',
      kind: WritersideSemanticKind.resource,
      attributes: {...commonConditionalAttributes, 'src'},
      block: false,
    ),
    'tooltip': WritersideElementCapability(
      name: 'tooltip',
      kind: WritersideSemanticKind.tooltip,
      attributes: {...commonConditionalAttributes, 'term'},
      block: false,
    ),
    'b': WritersideElementCapability(
      name: 'b',
      kind: WritersideSemanticKind.strong,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'strong': WritersideElementCapability(
      name: 'strong',
      kind: WritersideSemanticKind.strong,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'i': WritersideElementCapability(
      name: 'i',
      kind: WritersideSemanticKind.emphasis,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'em': WritersideElementCapability(
      name: 'em',
      kind: WritersideSemanticKind.emphasis,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'emphasis': WritersideElementCapability(
      name: 'emphasis',
      kind: WritersideSemanticKind.emphasis,
      attributes: commonConditionalAttributes,
      block: false,
    ),
    'include': WritersideElementCapability(
      name: 'include',
      kind: WritersideSemanticKind.include,
      attributes: {
        ...commonConditionalAttributes,
        'element-id',
        'from',
        'nullable',
        'origin',
        'use-filter',
      },
    ),
    'snippet': WritersideElementCapability(
      name: 'snippet',
      kind: WritersideSemanticKind.snippet,
      attributes: commonConditionalAttributes,
      requiredAttributes: {'id'},
      rendered: false,
    ),
    'if': WritersideElementCapability(
      name: 'if',
      kind: WritersideSemanticKind.condition,
      attributes: commonConditionalAttributes,
    ),
    'var': WritersideElementCapability(
      name: 'var',
      kind: WritersideSemanticKind.variable,
      attributes: {...commonConditionalAttributes, 'name', 'value'},
      requiredAttributes: {'name'},
      rendered: false,
    ),
    'br': WritersideElementCapability(
      name: 'br',
      kind: WritersideSemanticKind.lineBreak,
      block: false,
    ),
    'link-summary': WritersideElementCapability(
      name: 'link-summary',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'card-summary': WritersideElementCapability(
      name: 'card-summary',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'web-summary': WritersideElementCapability(
      name: 'web-summary',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'search-keyword': WritersideElementCapability(
      name: 'search-keyword',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'help-id': WritersideElementCapability(
      name: 'help-id',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'contribute-url': WritersideElementCapability(
      name: 'contribute-url',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'include-in-head': WritersideElementCapability(
      name: 'include-in-head',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'show-structure': WritersideElementCapability(
      name: 'show-structure',
      kind: WritersideSemanticKind.metadata,
      attributes: {...commonConditionalAttributes, 'rel'},
      rendered: false,
    ),
    'section-starting-page': WritersideElementCapability(
      name: 'section-starting-page',
      kind: WritersideSemanticKind.startingPage,
      parents: {'topic'},
    ),
    'spotlight': WritersideElementCapability(
      name: 'spotlight',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'primary': WritersideElementCapability(
      name: 'primary',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'secondary': WritersideElementCapability(
      name: 'secondary',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'misc': WritersideElementCapability(
      name: 'misc',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'cards': WritersideElementCapability(
      name: 'cards',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'links': WritersideElementCapability(
      name: 'links',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'group': WritersideElementCapability(
      name: 'group',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'compare': WritersideElementCapability(
      name: 'compare',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'tldr': WritersideElementCapability(
      name: 'tldr',
      kind: WritersideSemanticKind.section,
      attributes: {...commonConditionalAttributes, 'title', 'narrow'},
    ),
    'description': WritersideElementCapability(
      name: 'description',
      kind: WritersideSemanticKind.paragraph,
    ),
    'card': WritersideElementCapability(
      name: 'card',
      kind: WritersideSemanticKind.card,
      attributes: {
        ...commonConditionalAttributes,
        'href',
        'anchor',
        'origin',
        'summary',
        'image',
        'icon',
        'badge',
        'nullable',
      },
    ),
    'seealso': WritersideElementCapability(
      name: 'seealso',
      kind: WritersideSemanticKind.seealso,
      attributes: {...commonConditionalAttributes, 'title', 'style'},
    ),
    'category': WritersideElementCapability(
      name: 'category',
      kind: WritersideSemanticKind.category,
      attributes: {...commonConditionalAttributes, 'ref', 'sorted'},
      parents: {'seealso'},
    ),
    'api-doc': WritersideElementCapability(
      name: 'api-doc',
      kind: WritersideSemanticKind.api,
      attributes: {
        ...commonConditionalAttributes,
        'openapi-path',
        'tag',
        'endpoint',
        'method',
        'name',
        'webhook',
        'display',
        'depth',
        'generate-samples',
      },
    ),
    'api-endpoint': WritersideElementCapability(
      name: 'api-endpoint',
      kind: WritersideSemanticKind.api,
      attributes: {
        ...commonConditionalAttributes,
        'openapi-path',
        'tag',
        'endpoint',
        'method',
        'name',
        'webhook',
        'display',
        'depth',
        'generate-samples',
      },
    ),
    'api-schema': WritersideElementCapability(
      name: 'api-schema',
      kind: WritersideSemanticKind.api,
      attributes: {
        ...commonConditionalAttributes,
        'openapi-path',
        'tag',
        'endpoint',
        'method',
        'name',
        'webhook',
        'display',
        'depth',
        'generate-samples',
      },
    ),
    'api-webhook': WritersideElementCapability(
      name: 'api-webhook',
      kind: WritersideSemanticKind.api,
      attributes: {
        ...commonConditionalAttributes,
        'openapi-path',
        'tag',
        'endpoint',
        'method',
        'name',
        'webhook',
        'display',
        'depth',
        'generate-samples',
      },
    ),
    'request': WritersideElementCapability(
      name: 'request',
      kind: WritersideSemanticKind.section,
      attributes: {'type'},
    ),
    'response': WritersideElementCapability(
      name: 'response',
      kind: WritersideSemanticKind.section,
      attributes: {'type'},
    ),
    'sample': WritersideElementCapability(
      name: 'sample',
      kind: WritersideSemanticKind.codeBlock,
      attributes: {
        ...commonConditionalAttributes,
        'src',
        'include-lines',
        'lang',
        'title',
      },
    ),
    'web-file-name': WritersideElementCapability(
      name: 'web-file-name',
      kind: WritersideSemanticKind.metadata,
      rendered: false,
    ),
  };

  static bool isMarkdownSemanticBlock(String name) {
    final normalized = name.toLowerCase();
    final capability = capabilityFor(normalized);
    return (capability?.block ?? isKnownElement(normalized)) &&
        !_htmlCompatibleElements.contains(normalized);
  }

  /// Names present in the official 2026.07 semantic reference but currently
  /// represented as generic lossless elements by BusyMark.
  static const genericElementNames = {
    'anchor',
    'api-doc',
    'api-endpoint',
    'api-schema',
    'api-webhook',
    'card-summary',
    'card',
    'cards',
    'category',
    'compare',
    'contribute-url',
    'description',
    'format',
    'group',
    'help-id',
    'icon',
    'include-in-head',
    'inline-frame',
    'link-summary',
    'links',
    'misc',
    'primary',
    'primary-label',
    'property',
    'request',
    'response',
    'sample',
    'search-keyword',
    'secondary',
    'secondary-label',
    'section-starting-page',
    'seealso',
    'show-structure',
    'spotlight',
    'tldr',
    'ui-path',
    'value',
    'web-summary',
  };

  static bool isKnownElement(String name) =>
      elements.containsKey(name.toLowerCase()) ||
      genericElementNames.contains(name.toLowerCase()) ||
      writersideOfficialRules.containsKey(name.toLowerCase());

  static WritersideElementCapability? capabilityFor(String name) =>
      elements[name.toLowerCase()];

  static Iterable<String> childElementNames(String? parent) {
    final normalizedParent = parent?.toLowerCase();
    return {
      ...elements.keys,
      ...genericElementNames,
      ...writersideOfficialRules.keys,
    }.where((name) {
      final official = writersideOfficialRules[normalizedParent];
      if (official != null) return official.children.contains(name);
      final allowedParents = elements[name]?.parents ?? const <String>{};
      return allowedParents.isEmpty ||
          allowedParents.contains(normalizedParent);
    });
  }

  static Iterable<String> attributesFor(String element) => {
    ...?writersideOfficialRules[element.toLowerCase()]?.attributes.keys,
    ...?elements[element.toLowerCase()]?.attributes,
  };

  static Set<String> requiredAttributesFor(String element) => {
    ...?writersideOfficialRules[element]?.required,
    ...?elements[element]?.requiredAttributes,
  };

  static Set<String> valuesFor(String element, String attribute) {
    if (attribute == 'sortable') return const {'true', 'false'};
    if (attribute == 'generate-samples') {
      return const {'all', 'request', 'response', 'none'};
    }
    if (element == 'api-doc' && attribute == 'display') {
      return const {'all', 'endpoints', 'operations', 'webhooks'};
    }
    final rule = writersideOfficialRules[element];
    if (rule?.attributes[attribute] == 'boolean') {
      return const {'true', 'false'};
    }
    return rule?.values[attribute] ?? const {};
  }

  static String? invalidAttributeValue(
    String element,
    String attribute,
    String value,
  ) {
    if (value.contains('%')) return null;
    final values = valuesFor(element, attribute);
    if (values.isNotEmpty && !values.contains(value)) {
      return 'allowed: ${values.join(', ')}';
    }
    final type = writersideOfficialRules[element]?.attributes[attribute];
    if ({
          'integer',
          'int',
          'positiveInteger',
          'nonNegativeInteger',
        }.contains(type) ||
        {'colspan', 'rowspan'}.contains(attribute)) {
      final number = int.tryParse(value);
      if (number == null ||
          ((type == 'positiveInteger' ||
                  {'colspan', 'rowspan'}.contains(attribute)) &&
              number < 1) ||
          (type == 'nonNegativeInteger' && number < 0)) {
        return 'invalid integer';
      }
    }
    if (attribute == 'width' &&
        element == 'td' &&
        (double.tryParse(value) == null || double.parse(value) <= 0)) {
      return 'expected positive pixel width';
    }
    return null;
  }

  static WritersideAttributeReferenceKind? referenceKind(
    String element,
    String attribute,
  ) => switch (attribute) {
    'href' || 'from' => WritersideAttributeReferenceKind.topic,
    'anchor' ||
    'element-id' ||
    'rel' => WritersideAttributeReferenceKind.element,
    'instance' => WritersideAttributeReferenceKind.instance,
    'origin' => WritersideAttributeReferenceKind.module,
    'openapi-path' => WritersideAttributeReferenceKind.apiSpecification,
    'name' when element == 'var' => WritersideAttributeReferenceKind.variable,
    'ref' when element == 'category' =>
      WritersideAttributeReferenceKind.category,
    'src' when element == 'resource' =>
      WritersideAttributeReferenceKind.resource,
    'src' || 'preview-src' || 'dark-src'
        when element == 'img' || element == 'video' =>
      WritersideAttributeReferenceKind.image,
    _ => null,
  };
}
