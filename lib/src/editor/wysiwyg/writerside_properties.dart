import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'writerside_property_session.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../markdown/busymark_document.dart';
import '../../writerside/writerside_schema.dart';
import '../../writerside/writerside_effective_properties.dart';
import 'writerside_editing_adapter.dart';
import 'wysiwyg_inline_controller.dart';

String writersideElementLabel(
  BuildContext context,
  BusyBlock block, [
  BusyDocument? document,
  WritersideEffectiveProperties? resolver,
]) => switch (block.attributes['element']) {
  'topic' => context.l10n.topic,
  'chapter' => context.l10n.chapter,
  'procedure' => context.l10n.procedure,
  'step' => context.l10n.wsStep,
  'tabs' => context.l10n.tabs,
  'tab' => context.l10n.tab,
  'deflist' => context.l10n.wsDefinitionList,
  'def' => context.l10n.wsTerm,
  'list' => switch ((resolver ?? const WritersideEffectiveProperties())
      .resolve('list', 'type', block.attributes)
      .value) {
    'decimal' => context.l10n.orderedList,
    'alpha-lower' => context.l10n.wsLetteredList,
    'checkbox' => context.l10n.wsCheckboxList,
    'none' => context.l10n.wsMarkerlessList,
    _ => context.l10n.unorderedList,
  },
  'li' => context.l10n.wsListItem,
  'tldr' => context.l10n.wsTldr,
  'img' => context.l10n.image,
  'table' => context.l10n.table,
  'include' => context.l10n.wsIncludeContent,
  'video' => context.l10n.video,
  _ when block.isSourceProtected || block.preserveRaw =>
    block.attributes['element'] ?? context.l10n.source,
  _ => switch (block.kind) {
    BusyBlockKind.heading =>
      (document == null
              ? block.attributes['level'] == '1'
              : WritersideEditingAdapter.topicHeading(document)?.id == block.id)
          ? context.l10n.topic
          : context.l10n.chapter,
    BusyBlockKind.image => context.l10n.image,
    BusyBlockKind.table => context.l10n.table,
    BusyBlockKind.codeBlock => context.l10n.codeBlock,
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => context.l10n.wsListItem,
    BusyBlockKind.blockquote ||
    BusyBlockKind.writersideAdmonition => context.l10n.admonition,
    _ => context.l10n.paragraph,
  },
};

/// Subordinate, non-modal authoring properties. Targets are supplied by the
/// workspace, never inferred from whichever property entry happens to have focus.
String _elementExcerpt(BusyBlock block) {
  if (block.plainText.trim().isNotEmpty) {
    return block.plainText.split('\n').first;
  }
  for (final child in block.children) {
    final excerpt = _elementExcerpt(child);
    if (excerpt.isNotEmpty) return excerpt;
  }
  return '';
}

class BusyMarkWritersideProperties extends StatelessWidget {
  const BusyMarkWritersideProperties({
    super.key,
    required this.document,
    required this.path,
    required this.target,
    required this.topicSelected,
    required this.onTargetSelected,
    required this.onClose,
    required this.onProperty,
    required this.onHeadingText,
    required this.onTopicProperty,
    required this.onManageItem,
    this.effectiveProperties = const WritersideEffectiveProperties(),
    this.documentIdentity,
    this.session,
    this.readOnly = false,
    this.onSourceLocation,
    this.onChooseInclude,
    this.onChooseCodeSource,
    this.inlineTarget,
    this.onInlineProperty,
    this.videoDraft = false,
    this.onInsertVideo,
    this.onNavigation,
    this.onRenameTopic,
    this.onEditTitles,
    this.hasFileIdentity = true,
    this.navigationEditable = true,
  });
  final WritersideEffectiveProperties effectiveProperties;
  final String? documentIdentity;
  final WritersidePropertySession? session;
  final bool readOnly;
  final VoidCallback? onSourceLocation;
  final VoidCallback? onChooseInclude;
  final Future<String?> Function()? onChooseCodeSource;
  final BusyDocument document;
  final List<BusyBlock> path;
  final BusyBlock? target;
  final bool topicSelected;
  final ValueChanged<String> onTargetSelected;
  final VoidCallback onClose;
  final bool Function(String, String?) onProperty;
  final bool Function(String) onHeadingText;
  final bool Function(String, String) onTopicProperty;
  final void Function(String? itemId, int? direction, bool remove) onManageItem;
  final BusyInlineStyleRange? inlineTarget;
  final bool Function(String, String)? onInlineProperty;
  final bool videoDraft;
  final bool Function(String)? onInsertVideo;
  final bool Function(bool present, String forElements, String depth)?
  onNavigation;
  final VoidCallback? onRenameTopic;
  final VoidCallback? onEditTitles;
  final bool hasFileIdentity;
  final bool navigationEditable;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final block = target;
    final inlineTag = switch (inlineTarget?.kind) {
      BusyInlineKind.image => 'img',
      BusyInlineKind.link => 'a',
      BusyInlineKind.writersideShortcut => 'shortcut',
      _ => null,
    };
    final tag =
        inlineTag ??
        (block == null
            ? ''
            : WritersideEditingAdapter.propertyTag(document, block));
    final nativeHeading =
        block != null &&
        WritersideEditingAdapter.isNativeHeading(document, block);
    final attrs =
        inlineTarget?.attributes ??
        block?.attributes ??
        const <String, String>{};
    final nativeOwner = path
        .where(
          (b) =>
              b.attributes['busymark-list-form'] == 'markdown' &&
              b.children.any((child) => child.id == block?.id),
        )
        .lastOrNull;
    final unsafeItemConversion =
        inlineTarget == null &&
        nativeOwner != null &&
        WritersideEditingAdapter.nativeListHasMixedMarkers(nativeOwner);
    final immutable =
        readOnly ||
        unsafeItemConversion ||
        block?.isSourceProtected == true ||
        block?.preserveRaw == true;
    final offered = <String>{};
    String attributeLabel(String attribute, String label) {
      final name = switch (attribute) {
        'language' => 'lang',
        'busymark-ignored-href' => 'href',
        _ => attribute,
      };
      return name == label || attribute == 'reference'
          ? label
          : '$label ($name)';
    }

    Widget resetOverride(String attribute) => BusyMarkHeaderIconButton(
      icon: BusyMarkGlyphs.windowClose,
      tooltip: l.wsUseDefault,
      onPressed: immutable
          ? null
          : () {
              if (!(session?.flush() ?? true)) return;
              if (inlineTarget != null) {
                onInlineProperty?.call(attribute, '');
              } else {
                onProperty(attribute, null);
              }
            },
    );
    Widget entry(
      String attribute,
      String label, {
      String? value,
      bool topic = false,
      bool inline = false,
      bool enabled = true,
      Future<String?> Function()? chooseFile,
      String? supportingText,
    }) {
      final name = attribute == 'language' ? 'lang' : attribute;
      offered.add(name);
      final eligible = topic
          ? attribute == 'switcher-label'
          : inlineTarget != null
          ? attribute == 'reference' ||
                attribute == 'busymark-ignored-href' ||
                WritersideSchema.attributesFor(tag).contains(name)
          : block != null &&
                WritersideEditingAdapter.propertyAttributes(
                  document,
                  block,
                ).contains(name);
      if (!eligible) return const SizedBox.shrink();
      return _PropertyTextEntry(
        key: ValueKey(
          'writerside-property-${document.filePath}-${topic
              ? 'document'
              : nativeHeading
              ? 'heading-${block.id}'
              : 'element-${block?.id}'}-$attribute',
        ),
        session: session,
        readOnly: immutable || !enabled,
        label: attributeLabel(attribute, label),
        chooseFile: chooseFile,
        supportingText: supportingText,
        help: switch (name) {
          'id' when nativeHeading => l.wsGeneratedAnchor,
          'title' when nativeHeading => l.wsTitleOverrideExplanation,
          'filter' => l.wsFilterExplanation,
          'instance' => l.wsInstanceExplanation,
          'ignore-vars' => l.wsIgnoreVariablesExplanation,
          _ => null,
        },
        value: value ?? attrs[attribute] ?? '',
        apply: (value) => inline || inlineTarget != null
            ? onInlineProperty?.call(attribute, value) ?? false
            : topic
            ? onTopicProperty(attribute, value)
            : onProperty(
                attribute,
                value.isEmpty && attribute != 'alt' ? null : value,
              ),
      );
    }

    final externalImage =
        tag == 'img' &&
        RegExp(
          r'^(?:https?:)?//',
        ).hasMatch(inlineTarget?.destination ?? attrs['src'] ?? '');
    Widget dimension(String attribute, String label) {
      if (externalImage && attrs[attribute]?.isNotEmpty != true) {
        offered.add(attribute);
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          Expanded(child: entry(attribute, label, enabled: !externalImage)),
          if (externalImage && attrs[attribute]?.isNotEmpty == true)
            resetOverride(attribute),
        ],
      );
    }

    final parentList = path
        .where((b) => b.attributes['element'] == 'deflist' && b.id != block?.id)
        .lastOrNull;
    final listAttributes = parentList == null
        ? null
        : effectiveProperties.defaultsFor('deflist', parentList.attributes);
    final collapse = effectiveProperties.resolve(
      tag,
      'collapsible',
      attrs,
      definitionList: listAttributes,
    );
    Widget enumRow(String attribute, String label, {bool active = true}) {
      offered.add(attribute);
      if (!WritersideSchema.attributesFor(tag).contains(attribute)) {
        return const SizedBox.shrink();
      }
      final property = effectiveProperties.resolve(
        tag,
        attribute,
        attrs,
        definitionList: listAttributes,
      );
      final value = attrs[attribute] ?? '';
      if (!active && value.isEmpty) return const SizedBox.shrink();
      final allowed = WritersideSchema.valuesFor(tag, attribute).toList();
      final values = [
        '',
        ...allowed,
        if (value.isNotEmpty && !allowed.contains(value)) value,
      ];
      String valueLabel(String v) => switch (v) {
        'expanded' => l.wsExpanded,
        'collapsed' => l.wsCollapsed,
        'inherited' => l.wsInherited,
        'bullet' => l.unorderedList,
        'decimal' => l.orderedList,
        'alpha-lower' => l.wsLetteredList,
        'checkbox' => l.wsCheckboxList,
        'none' when attribute == 'type' => l.wsMarkerlessList,
        'none' when attribute == 'sorted' => l.wsNoSorting,
        'asc' => l.wsAscending,
        'desc' => l.wsDescending,
        'aswritten' => l.wsAsWritten,
        'sentence' => l.wsSentenceCase,
        'title' => l.wsTitleCase,
        'lower' => l.wsLowerCase,
        'upper' => l.wsUpperCase,
        'true' => l.wsEnabled,
        'false' => l.wsDisabled,
        'full' => l.wsFullLayout,
        'medium' => l.wsMediumLayout,
        'narrow' => l.wsNarrowLayout,
        'compact' => l.wsCompactLayout,
        'wide' => l.wsWideLayout,
        _ => v,
      };
      final origin = switch (property.origin) {
        WritersidePropertyOrigin.element => l.wsOriginElement,
        WritersidePropertyOrigin.ancestor => l.wsOriginAncestor,
        WritersidePropertyOrigin.module => l.wsOriginModule,
        WritersidePropertyOrigin.markdownMarker => l.wsNativeMarkers,
        WritersidePropertyOrigin.builtIn => l.wsOriginBuiltIn,
        WritersidePropertyOrigin.unresolved => l.wsOriginUnresolved,
      };
      final resolved = property.value;
      final summary = resolved == null
          ? l.wsPropertyUnresolved
          : value.isEmpty
          ? property.origin == WritersidePropertyOrigin.module
                ? l.wsDefaultPropertyOrigin(valueLabel(resolved), l.wsModule)
                : property.origin == WritersidePropertyOrigin.ancestor
                ? l.wsDefaultPropertyOrigin(valueLabel(resolved), l.wsParent)
                : l.wsDefaultProperty(valueLabel(resolved))
          : resolved != value
          ? l.wsResolvedProperty(valueLabel(resolved))
          : null;
      final provenance = l.wsEffectiveProperty(
        resolved == null ? l.wsPropertyUnresolved : valueLabel(resolved),
        origin,
      );
      final help = [
        provenance,
        if (property.limitation == 'module-caps-ignored') l.wsModuleCapsIgnored,
        if (attribute == 'ignore-vars') l.wsIgnoreVariablesExplanation,
      ].join('\n');
      final subtitle = [
        if (summary != null) summary,
        if (property.limitation == 'module-caps-ignored') l.wsModuleCapsIgnored,
        if (!active) l.wsPropertiesInactive,
      ].join('\n');
      return _PropertyContextHelp(
        help: help,
        mergeSemantics: active,
        child: Row(
          children: [
            Expanded(
              child: BusyMarkComboRow<String>(
                enabled: !immutable && active,
                subtitle: subtitle.isEmpty ? null : subtitle,
                tooltip: help,
                title: attributeLabel(attribute, label),
                values: values,
                selected: value,
                labelFor: (v) => v.isEmpty ? l.wsUseDefault : valueLabel(v),
                onSelected: (v) {
                  if (!immutable && (active || v.isEmpty)) {
                    if (inlineTarget != null) {
                      onInlineProperty?.call(attribute, v);
                    } else {
                      onProperty(attribute, v.isEmpty ? null : v);
                    }
                  }
                },
                width: 125,
              ),
            ),
            if (!active && value.isNotEmpty) resetOverride(attribute),
          ],
        ),
      );
    }

    Widget stateRow() => enumRow(
      'default-state',
      l.wsPublishedState,
      active: collapse.value == 'true',
    );

    final ancestors = path
        .where(
          (b) =>
              busyMarkIsWritersideContainer(b) ||
              b.kind == BusyBlockKind.heading ||
              {
                BusyBlockKind.unorderedListItem,
                BusyBlockKind.orderedListItem,
                BusyBlockKind.taskListItem,
              }.contains(b.kind) ||
              b.id == block?.id,
        )
        .where(
          (b) =>
              !(b.attributes['element'] == 'topic' ||
                  WritersideEditingAdapter.topicHeading(document)?.id == b.id),
        )
        .toList();
    final values = [
      '@topic',
      ...{for (final b in ancestors) b.id},
    ];
    final selected = topicSelected ? '@topic' : block?.id ?? '@topic';
    if (!values.contains(selected)) values.add(selected);
    final identity = [
      if (attrs['id']?.isNotEmpty == true) attrs['id']!,
      if (inlineTarget != null && block != null)
        block.plainText.substring(inlineTarget!.start, inlineTarget!.end)
      else if (block != null)
        block.attributes['title'] ??
            block.attributes['busymark-title-label'] ??
            (block.kind == BusyBlockKind.codeBlock
                ? block.attributes['src'] ?? ''
                : block.plainText.split('\n').first),
    ].where((v) => v.isNotEmpty).join(' · ');
    final hasEditableTitle =
        !immutable &&
        inlineTarget == null &&
        block != null &&
        (block.kind == BusyBlockKind.heading ||
            WritersideEditingAdapter.titleElements.contains(tag));
    final rows = <Widget>[];
    if (videoDraft) {
      rows.add(
        _PropertyTextEntry(
          key: const ValueKey('writerside-video-source'),
          commitOnBlur: false,
          session: session,
          readOnly: immutable,
          label: attributeLabel('src', l.source),
          value: '',
          apply: (v) => onInsertVideo?.call(v) ?? false,
        ),
      );
    } else if (inlineTarget != null) {
      final selectedInline = inlineTarget!;
      switch (selectedInline.kind) {
        case BusyInlineKind.link:
          rows.add(
            entry('href', l.wsLinkTarget, value: selectedInline.destination),
          );
          if (attrs['busymark-ignored-href'] case final ignored?) {
            rows.add(
              entry(
                'busymark-ignored-href',
                'href',
                value: ignored,
                enabled: false,
              ),
            );
            rows.add(Text(l.wsPropertiesProtected));
          }
          rows.add(entry('origin', l.wsHelpModule));
        case BusyInlineKind.image:
          rows.add(entry('src', l.source, value: selectedInline.destination));
          rows.add(
            entry(
              'alt',
              l.altText,
              value:
                  attrs['alt'] ??
                  block!.plainText.substring(
                    selectedInline.start,
                    selectedInline.end,
                  ),
            ),
          );
          if (externalImage) rows.add(Text(l.wsExternalImageSize));
          rows.add(dimension('width', l.wsWidth));
          rows.add(dimension('height', l.wsHeight));
          rows.add(enumRow('style', l.wsImageDisplay));
          rows.add(enumRow('thumbnail', l.wsImageThumbnail));
          rows.add(entry('preview-src', l.wsPreviewImage));
        case BusyInlineKind.writersideVariable:
          rows.add(
            entry(
              'reference',
              l.wsVariableReference,
              value:
                  attrs['reference'] ??
                  block!.plainText.substring(
                    selectedInline.start,
                    selectedInline.end,
                  ),
            ),
          );
        case BusyInlineKind.writersideShortcut:
          rows.add(entry('key', l.wsActionId));
          rows.add(entry('from-keymap-of', l.wsKeymapHelpInstance));
          rows.add(entry('force-layout', l.keyboardLayout));
        default:
          break;
      }
    } else if (topicSelected) {
      if (document.isXmlTopic) offered.add('id');
      if (block != null) {
        rows.add(
          nativeHeading
              ? _PropertyTextEntry(
                  key: ValueKey(
                    'writerside-heading-title-${document.filePath}-${block.id}',
                  ),
                  session: session,
                  readOnly: immutable,
                  label: l.wsHeadingText,
                  value: block.plainText,
                  apply: onHeadingText,
                )
              : entry('title', l.wsDefaultTitle),
        );
      } else if (!document.isXmlTopic) {
        rows.add(Text(l.wsMissingTopicHeading));
      }
      final identity = hasFileIdentity && document.filePath.isNotEmpty
          ? p.basenameWithoutExtension(document.filePath)
          : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.wsTopicIdentity),
              SelectableText(
                identity ?? l.wsPropertiesUnresolved,
                key: const ValueKey('writerside-topic-id'),
              ),
              if (onRenameTopic != null && identity != null)
                TextButton(
                  onPressed: immutable
                      ? null
                      : () {
                          if (session?.transition() ?? true) onRenameTopic!();
                        },
                  child: Text(l.renameTopicFile),
                ),
            ],
          ),
        ),
      );
      if (document.isXmlTopic && identity != null && attrs['id'] != identity) {
        rows.add(
          Text(
            '${l.wsTopicIdentityMismatch} id="${attrs["id"] ?? ""}" → $identity',
          ),
        );
      }
      if (!document.isXmlTopic &&
          document.blocks
                  .where(
                    (b) =>
                        WritersideEditingAdapter.isNativeHeading(document, b) &&
                        b.attributes['level'] == '1',
                  )
                  .length >
              1) {
        rows.add(Text(l.wsMultipleTopicHeadings));
      }
      if (onEditTitles != null) {
        rows.add(
          TextButton(
            onPressed: immutable
                ? null
                : () {
                    if (session?.transition() ?? true) onEditTitles!();
                  },
            child: Text(l.tocEditTitleAction),
          ),
        );
      }
    } else if (block != null) {
      if (tag == 'list') {
        rows.add(enumRow('type', l.wsListType));
        final type = effectiveProperties.resolve(tag, 'type', attrs).value;
        final numbered = type == 'decimal' || type == 'alpha-lower';
        final startDefault = effectiveProperties.resolve(tag, 'start', attrs);
        final startSummary =
            startDefault.origin == WritersidePropertyOrigin.module
            ? l.wsDefaultPropertyOrigin(
                startDefault.value ?? l.wsPropertyUnresolved,
                l.wsModule,
              )
            : attrs['busymark-native-list-start'] == null
            ? l.wsDefaultProperty(startDefault.value ?? l.wsPropertyUnresolved)
            : l.wsListMarkerStart(attrs['busymark-native-list-start']!);
        if (numbered || attrs.containsKey('start')) {
          rows.add(
            Row(
              children: [
                Expanded(
                  child: entry(
                    'start',
                    l.wsStartingNumber,
                    enabled: numbered,
                    supportingText: startSummary,
                  ),
                ),
                if (!numbered && attrs.containsKey('start'))
                  resetOverride('start'),
              ],
            ),
          );
        } else {
          offered.add('start');
        }
        rows.add(entry('columns', l.columns));
        rows.add(enumRow('sorted', l.wsListSorting));
      }
      if (block.kind == BusyBlockKind.heading) {
        if (!document.isXmlTopic && !block.attributes.containsKey('element')) {
          rows.add(
            _PropertyTextEntry(
              key: ValueKey('writerside-heading-title-${block.id}'),
              session: session,
              readOnly: immutable,
              label: l.wsHeadingText,
              value: block.plainText,
              apply: onHeadingText,
            ),
          );
        } else {
          rows.add(entry('title', l.wsDefaultTitle));
        }
      } else if (WritersideEditingAdapter.titleElements.contains(tag)) {
        rows.add(
          entry(
            'title',
            tag == 'def' ? l.wsTerm : l.wsTitle,
            value: block.plainText,
          ),
        );
      }
      if (WritersideSchema.attributesFor(tag).contains('id')) {
        rows.add(
          entry(
            'id',
            l.wsElementAnchor,
            value: attrs['generatedId'] == 'true' ? '' : attrs['id'],
            supportingText: attrs['generatedId'] == 'true'
                ? l.wsGeneratedAnchorValue(attrs['id'] ?? '')
                : null,
          ),
        );
      }
      if ({'chapter', 'code-block', 'procedure', 'deflist'}.contains(tag)) {
        rows.add(enumRow('collapsible', l.wsCollapsible));
        rows.add(stateRow());
      }
      if (tag == 'def') rows.add(stateRow());
      if (tag == 'code-block') {
        rows.add(entry('language', l.language));
        rows.add(entry('src', l.wsSourceFile, chooseFile: onChooseCodeSource));
        if (collapse.value == 'true' ||
            attrs['collapsed-title']?.isNotEmpty == true) {
          rows.add(
            Row(
              children: [
                Expanded(
                  child: entry(
                    'collapsed-title',
                    l.wsCollapsedTitle,
                    enabled: collapse.value == 'true',
                  ),
                ),
                if (collapse.value != 'true' &&
                    attrs['collapsed-title']?.isNotEmpty == true)
                  resetOverride('collapsed-title'),
              ],
            ),
          );
        }
        rows.add(entry('include-lines', l.wsIncludeLines));
        if (attrs['src']?.isNotEmpty == true ||
            attrs['include-symbol']?.isNotEmpty == true) {
          rows.add(
            Row(
              children: [
                Expanded(
                  child: entry(
                    'include-symbol',
                    l.wsIncludeSymbol,
                    enabled: attrs['src']?.isNotEmpty == true,
                  ),
                ),
                if (attrs['src']?.isNotEmpty != true)
                  resetOverride('include-symbol'),
              ],
            ),
          );
        } else {
          offered.add('include-symbol');
        }
        rows.add(entry('emphasize-lines', l.wsEmphasizeLines));
      }
      if (tag == 'img') {
        rows.add(entry('src', l.source));
        rows.add(entry('alt', l.altText));
        if (externalImage) rows.add(Text(l.wsExternalImageSize));
        rows.add(dimension('width', l.wsWidth));
        rows.add(dimension('height', l.wsHeight));
        rows.add(enumRow('style', l.wsImageDisplay));
        rows.add(enumRow('thumbnail', l.wsImageThumbnail));
        rows.add(entry('preview-src', l.wsPreviewImage));
      }
      if (tag == 'deflist') {
        rows.add(enumRow('type', l.wsListLayout));
      }
      if (tag == 'tabs') rows.add(entry('group', l.wsSyncGroup));
      if (tag == 'tab') rows.add(entry('group-key', l.wsTabKey));
      if (busyAdmonitionStyleFromName(tag) != null ||
          block.kind == BusyBlockKind.blockquote &&
              attrs[busyMarkWritersideAdmonitionAttribute] == 'true') {
        final value =
            busyAdmonitionStyleFromName(attrs['style'] ?? tag) ??
            BusyAdmonitionStyle.tip;
        rows.add(
          BusyMarkComboRow<BusyAdmonitionStyle>(
            title: l.admonition,
            values: BusyAdmonitionStyle.values,
            selected: value,
            labelFor: (v) => switch (v) {
              BusyAdmonitionStyle.tip => l.tip,
              BusyAdmonitionStyle.note => l.note,
              BusyAdmonitionStyle.warning => l.warning,
              BusyAdmonitionStyle.quote => l.quote,
            },
            onSelected: (v) => onProperty('admonition-type', v.name),
            width: 120,
          ),
        );
      }
      if (tag == 'include') {
        if (onChooseInclude != null) {
          rows.add(
            TextButton(
              onPressed: readOnly ? null : onChooseInclude,
              child: Text(l.wsIncludeContent),
            ),
          );
        }
        rows.add(entry('from', l.topic));
        rows.add(entry('element-id', l.wsIncludedElement));
        rows.add(entry('origin', l.wsHelpModule));
        rows.add(entry('use-filter', l.wsFilter));
      }
      if (tag == 'video') {
        rows.add(entry('src', l.source));
        rows.add(entry('preview-src', l.wsPreviewImage));
      }
      if (WritersideSchema.attributesFor(tag).contains('switcher-key') &&
          !{'topic', 'chapter', 'p', 'list'}.contains(tag)) {
        rows.add(entry('switcher-key', l.wsSwitcherKey));
      }
      if (inlineTarget case final inline?) {
        if (inline.kind == BusyInlineKind.writersideVariable) {
          rows.add(
            entry(
              'reference',
              l.wsVariableReference,
              value:
                  inline.attributes['reference'] ??
                  block.plainText.substring(inline.start, inline.end),
              inline: true,
            ),
          );
        } else if (inline.kind == BusyInlineKind.writersideShortcut) {
          rows.add(
            entry(
              'key',
              l.wsActionId,
              value: inline.attributes['key'] ?? '',
              inline: true,
            ),
          );
          rows.add(
            entry(
              'from-keymap-of',
              l.wsKeymapHelpInstance,
              value: inline.attributes['from-keymap-of'] ?? '',
              inline: true,
            ),
          );
          rows.add(
            entry(
              'force-layout',
              l.keyboardLayout,
              value: inline.attributes['force-layout'] ?? '',
              inline: true,
            ),
          );
        }
      }
      if ({'tabs', 'procedure', 'deflist'}.contains(tag) &&
          !(tag == 'tabs' &&
              block.children.any((b) => b.kind == BusyBlockKind.codeBlock) &&
              !block.children.any((b) => b.attributes['element'] == 'tab'))) {
        rows.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BusyMarkHeaderIconButton(
              icon: BusyMarkGlyphs.add,
              tooltip: l.wsAddItem,
              onPressed: immutable
                  ? null
                  : () => onManageItem(null, null, false),
            ),
          ),
        );
        final itemTag = switch (tag) {
          'tabs' => 'tab',
          'procedure' => 'step',
          _ => 'def',
        };
        for (final item in block.children.where(
          (b) => b.attributes['element'] == itemTag,
        )) {
          rows.add(
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.plainText.isEmpty
                        ? writersideElementLabel(context, item)
                        : item.plainText,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                BusyMarkHeaderIconButton(
                  icon: BusyMarkGlyphs.upArrow,
                  tooltip: l.moveSectionUp,
                  onPressed: immutable
                      ? null
                      : () => onManageItem(item.id, -1, false),
                ),
                BusyMarkHeaderIconButton(
                  icon: BusyMarkGlyphs.downArrow,
                  tooltip: l.moveSectionDown,
                  onPressed: immutable
                      ? null
                      : () => onManageItem(item.id, 1, false),
                ),
                BusyMarkHeaderIconButton(
                  icon: BusyMarkGlyphs.delete,
                  tooltip: l.removeAction,
                  onPressed:
                      !immutable &&
                          block.children
                                  .where(
                                    (b) => b.attributes['element'] == itemTag,
                                  )
                                  .length >
                              1
                      ? () => onManageItem(item.id, null, true)
                      : null,
                ),
              ],
            ),
          );
        }
      }
    }
    final primaryAttributes = offered.toSet();
    final advanced = <Widget>[];
    final secondary = <Widget>[];
    if (topicSelected && inlineTarget == null) {
      final root = document.blocks
          .where((b) => b.attributes['element'] == 'topic')
          .firstOrNull;
      final declarations = (root?.children ?? document.blocks)
          .where((b) => b.attributes['element'] == 'show-structure')
          .toList();
      secondary.add(
        _PropertySection(
          key: const ValueKey('writerside-topic-navigation'),
          storageIdentity:
              'writerside-navigation-${documentIdentity ?? document.filePath}',
          title: l.wsTopicNavigation,
          session: session,
          children: [
            if (!navigationEditable) Text(l.wsPropertiesProtected),
            _TopicNavigation(
              key: ValueKey('navigation-${document.filePath}'),
              session: session,
              declarations: declarations,
              readOnly: immutable || !navigationEditable,
              apply:
                  onNavigation ??
                  (present, forElements, depth) => onTopicProperty(
                    '@navigation',
                    !present
                        ? 'default'
                        : forElements == 'none'
                        ? 'none'
                        : 'all',
                  ),
            ),
          ],
        ),
      );
      advanced.add(Text(l.wsDocumentOptions));
      advanced.add(
        entry(
          'switcher-label',
          l.wsSwitcherLabel,
          value:
              root?.attributes['switcher-label'] ??
              document.frontMatter['switcher-label'] ??
              '',
          topic: true,
        ),
      );
      if (nativeHeading) {
        advanced.add(Text(l.wsHeadingOptions));
        advanced.add(Text(l.wsHeadingBuilderLimitation));
        advanced.add(
          entry(
            'id',
            l.wsElementAnchor,
            value: attrs['generatedId'] == 'true' ? '' : attrs['id'],
            supportingText: attrs['generatedId'] == 'true'
                ? l.wsGeneratedAnchorValue(attrs['id'] ?? '')
                : null,
          ),
        );
      }
    }
    String fieldLabel(String name) => switch (name) {
      'filter' => l.wsFilter,
      'instance' => l.wsInstanceSelection,
      'help-id' => l.wsContextHelp,
      'ignore-vars' => l.wsIgnoreVariables,
      'caps' => l.wsCapitalization,
      'switcher-key' => l.wsSwitcherKey,
      'is-library' => l.wsLibraryTopic,
      'last-modified' => l.wsLastModified,
      _ => name,
    };
    if (block != null &&
        !videoDraft &&
        (inlineTarget == null || inlineTag != null)) {
      if (nativeHeading && (!topicSelected || attrs.containsKey('title'))) {
        advanced.add(entry('title', l.wsTitleOverride));
      }
      final properties =
          (inlineTag == null
                  ? WritersideEditingAdapter.propertyAttributes(document, block)
                  : WritersideSchema.attributesFor(tag))
              .where(
                (a) =>
                    !offered.contains(a) &&
                    !{'title', 'level'}.contains(a) &&
                    !({'deflist', 'list'}.contains(tag) &&
                        a == 'style' &&
                        !attrs.containsKey(a)),
              )
              .toList()
            ..sort();
      for (final name in properties) {
        final allowed = WritersideSchema.valuesFor(tag, name);
        advanced.add(
          allowed.isEmpty
              ? entry(name, fieldLabel(name))
              : enumRow(
                  name,
                  fieldLabel(name),
                  active: !(tag == 'def' && name == 'collapsible'),
                ),
        );
      }
      final unsupported = WritersideEditingAdapter.sourceAttributes(block).keys
          .where(
            (a) =>
                !a.startsWith('xmlns') &&
                !(inlineTag == null
                        ? WritersideEditingAdapter.propertyAttributes(
                            document,
                            block,
                          )
                        : WritersideSchema.attributesFor(tag))
                    .contains(a),
          )
          .toList();
      if (unsupported.isNotEmpty) {
        advanced.add(
          Text('${l.wsUnsupportedProperties} ${unsupported.join(', ')}'),
        );
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: BusyMarkSurfaceColors.of(context).panel),
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.wsElementProperties,
                      style: busyMarkSectionHeaderStyle(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BusyMarkHeaderIconButton(
                    icon: BusyMarkGlyphs.windowClose,
                    tooltip: l.close,
                    onPressed: () {
                      if (videoDraft) session?.revertAll();
                      if (session?.transition() ?? true) onClose();
                    },
                  ),
                ],
              ),
            ),
            if (session != null)
              ListenableBuilder(
                listenable: session!,
                builder: (context, _) {
                  final reason = session!.feedback;
                  if (reason == null || session!.hasPending) {
                    return const SizedBox.shrink();
                  }
                  final message = switch (reason) {
                    WritersidePropertyRejection.stale => l.wsPropertiesConflict,
                    WritersidePropertyRejection.readOnly =>
                      l.wsPropertiesReadOnly,
                    WritersidePropertyRejection.unresolved =>
                      l.wsPropertiesUnresolved,
                    _ => l.wsPropertyInvalid,
                  };
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      session!.detail ?? message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                },
              ),
            if (readOnly ||
                unsafeItemConversion ||
                block?.isSourceProtected == true ||
                block?.preserveRaw == true)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  readOnly ? l.wsPropertiesReadOnly : l.wsPropertiesProtected,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Tooltip(
                      message: block == null
                          ? l.wsElementSelector
                          : '${writersideElementLabel(context, block, document)} · ${block.attributes['id'] ?? ''} · ${block.attributes['title'] ?? block.attributes['busymark-title-label'] ?? block.plainText}',
                      child: BusyMarkGroupedList(
                        filled: true,
                        children: [
                          BusyMarkComboRow<String>(
                            title: l.wsElementSelector,
                            values: values,
                            selected: selected,
                            labelFor: (id) => id == '@topic'
                                ? l.wsTopicProperties
                                : (() {
                                    final b = path
                                        .where((b) => b.id == id)
                                        .firstOrNull;
                                    return inlineTarget != null &&
                                            id == block?.id
                                        ? switch (inlineTarget!.kind) {
                                            BusyInlineKind.image => l.image,
                                            BusyInlineKind.link => l.link,
                                            BusyInlineKind.writersideVariable =>
                                              l.wsVariableReference,
                                            _ => l.keyboardShortcuts,
                                          }
                                        : b == null
                                        ? l.wsElementProperties
                                        : b.id == block?.id
                                        ? writersideElementLabel(
                                            context,
                                            b,
                                            document,
                                            effectiveProperties,
                                          )
                                        : [
                                            writersideElementLabel(
                                              context,
                                              b,
                                              document,
                                              effectiveProperties,
                                            ),
                                            b.attributes['id'] ??
                                                b.attributes['title'] ??
                                                b.attributes['busymark-title-label'] ??
                                                _elementExcerpt(b),
                                            if (b.attributes['element'] ==
                                                'list')
                                              l.wsListLevel(
                                                '${path.takeWhile((p) => p.id != b.id).where((p) => p.attributes['element'] == 'list').length + 1}',
                                              ),
                                          ].where((v) => v.isNotEmpty).join(' · ');
                                  })(),
                            onSelected: (value) {
                              if (session?.transition() ?? true) {
                                onTargetSelected(value);
                              }
                            },
                            width: 160,
                          ),
                        ],
                      ),
                    ),
                    if (identity.isNotEmpty &&
                        !topicSelected &&
                        !hasEditableTitle)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 72),
                            child: Semantics(
                              excludeSemantics: true,
                              label:
                                  inlineTarget == null &&
                                      tag == 'p' &&
                                      block != null
                                  ? '${attrs['id'] ?? ''} ${block.plainText}'
                                  : identity,
                              child: Text(
                                identity,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                key: const ValueKey(
                                  'writerside-properties-identity',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (rows.isNotEmpty)
                      AbsorbPointer(
                        absorbing:
                            readOnly ||
                            block?.isSourceProtected == true ||
                            block?.preserveRaw == true,
                        child: BusyMarkGroupedList(
                          filled: true,
                          children: rows,
                        ),
                      ),
                    ...secondary,
                    if (advanced.isNotEmpty)
                      _PropertySection(
                        key: const ValueKey('writerside-advanced'),
                        storageIdentity:
                            'writerside-advanced-${documentIdentity ?? document.filePath}',
                        session: session,
                        title: l.advanced,
                        subtitle:
                            WritersideEditingAdapter.sourceAttributes(
                                  block ??
                                      const BusyBlock(
                                        id: '',
                                        kind: BusyBlockKind.paragraph,
                                      ),
                                ).keys.any(
                                  (a) =>
                                      !primaryAttributes.contains(a) ||
                                      nativeHeading && a == 'title',
                                ) ||
                                document.frontMatter.containsKey(
                                  'switcher-label',
                                )
                            ? l.wsSettingsPresent
                            : null,
                        children: [
                          BusyMarkGroupedList(filled: true, children: advanced),
                        ],
                      ),
                    if (onSourceLocation != null)
                      TextButton(
                        onPressed: () {
                          if (session?.flush() ?? true) onSourceLocation!();
                        },
                        child: Text(l.wsShowInSource),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disclosure state is presentation only. Hiding a pending field is a guarded
/// transition, just like closing the inspector or changing its target.
class _PropertySection extends StatefulWidget {
  const _PropertySection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.session,
    required this.storageIdentity,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final WritersidePropertySession? session;
  final String storageIdentity;
  @override
  State<_PropertySection> createState() => _PropertySectionState();
}

class _PropertySectionState extends State<_PropertySection> {
  bool expanded = false;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      expanded =
          PageStorage.maybeOf(
            context,
          )?.readState(context, identifier: widget.storageIdentity) ==
          true;
    }
  }

  @override
  void didUpdateWidget(covariant _PropertySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storageIdentity != widget.storageIdentity) {
      expanded =
          PageStorage.maybeOf(
            context,
          )?.readState(context, identifier: widget.storageIdentity) ==
          true;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: BusyMarkSurfaceColors.of(context).panel,
    child: Column(
      children: [
        ListTile(
          title: Text(widget.title),
          subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
          trailing: Icon(
            expanded ? BusyMarkGlyphs.upArrow : BusyMarkGlyphs.downArrow,
          ),
          onTap: () {
            if (expanded && !(widget.session?.flush() ?? true)) return;
            setState(() => expanded = !expanded);
            PageStorage.maybeOf(context)?.writeState(
              context,
              expanded,
              identifier: widget.storageIdentity,
            );
          },
        ),
        if (expanded) ...widget.children,
      ],
    ),
  );
}

class _TopicNavigation extends StatefulWidget {
  const _TopicNavigation({
    super.key,
    required this.declarations,
    required this.readOnly,
    required this.apply,
    this.session,
  });
  final List<BusyBlock> declarations;
  final bool readOnly;
  final bool Function(bool, String, String) apply;
  final WritersidePropertySession? session;
  @override
  State<_TopicNavigation> createState() => _TopicNavigationState();
}

class _TopicNavigationState extends State<_TopicNavigation> {
  late final _local = WritersidePropertySession();
  WritersidePropertySession get session => widget.session ?? _local;
  late WritersidePropertyDraft draft;
  final elements = TextEditingController();
  final depth = TextEditingController();
  final focus = FocusNode();
  bool custom = false;
  bool get protected =>
      widget.declarations.length > 1 ||
      widget.declarations.any(
        (b) => b.attributes.keys.any(
          {'instance', 'filter', 'switcher-key'}.contains,
        ),
      );
  Map<String, dynamic> get authored => widget.declarations.isEmpty
      ? {'present': false, 'for': '', 'depth': ''}
      : {
          'present': true,
          'for': widget.declarations.first.attributes['for'] ?? '',
          'depth': widget.declarations.first.attributes['depth'] ?? '',
        };
  void bind() {
    final apply = widget.apply;
    draft = session.bind('${widget.key}-show-structure', jsonEncode(authored), (
      value,
    ) {
      final values = jsonDecode(value) as Map<String, dynamic>;
      return apply(
        values['present'] as bool,
        values['for'] as String,
        values['depth'] as String,
      );
    });
    sync();
  }

  void sync() {
    final values = jsonDecode(draft.text) as Map<String, dynamic>;
    final forText = values['for'] == 'none' ? '' : values['for'] as String;
    if (elements.text != forText) elements.text = forText;
    if (depth.text != values['depth']) depth.text = values['depth'] as String;
  }

  @override
  void initState() {
    super.initState();
    bind();
    focus.addListener(() {
      if (!focus.hasFocus) session.commit(draft);
    });
    session.addListener(refresh);
  }

  void refresh() {
    if (mounted) {
      sync();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _TopicNavigation old) {
    super.didUpdateWidget(old);
    bind();
  }

  @override
  void dispose() {
    session.removeListener(refresh);
    elements.dispose();
    depth.dispose();
    focus.dispose();
    _local.dispose();
    super.dispose();
  }

  void edit() => session.edit(
    draft,
    jsonEncode({'present': true, 'for': elements.text, 'depth': depth.text}),
  );
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final values = jsonDecode(draft.text) as Map<String, dynamic>;
    final selected = custom
        ? 'custom'
        : values['present'] != true
        ? 'default'
        : values['for'] == 'none'
        ? 'none'
        : values['for'] == '' && values['depth'] == ''
        ? 'all'
        : 'custom';
    return Focus(
      focusNode: focus,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _RevertPropertyIntent(),
        },
        child: Actions(
          actions: {
            _RevertPropertyIntent: CallbackAction<_RevertPropertyIntent>(
              onInvoke: (_) {
                session.revert(draft);
                custom = false;
                return null;
              },
            ),
          },
          child: Column(
            children: [
              if (protected) Text(l.wsPropertiesProtected),
              BusyMarkComboRow<String>(
                title: l.wsNavigationElements,
                values: const ['default', 'all', 'none', 'custom'],
                selected: selected,
                enabled: !widget.readOnly && !protected,
                labelFor: (v) => switch (v) {
                  'default' => l.wsUseDefault,
                  'all' => l.wsNavigationAll,
                  'none' => l.wsNavigationNone,
                  _ => l.wsNavigationCustom,
                },
                onSelected: (v) {
                  if (!session.flush()) return;
                  if (v == 'custom') {
                    // Enter editing without inventing a published depth or element list.
                    setState(() => custom = true);
                  } else {
                    session.edit(
                      draft,
                      jsonEncode({
                        'present': v != 'default',
                        'for': v == 'none' ? 'none' : '',
                        'depth': '',
                      }),
                    );
                    if (session.commit(draft)) setState(() => custom = false);
                  }
                },
                width: 155,
              ),
              if (draft.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    draft.detail ?? l.wsPropertyInvalid,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (selected == 'custom') ...[
                BusyMarkGroupedTextEntry(
                  label: '${l.wsNavigationElements} (for)',
                  controller: elements,
                  readOnly: widget.readOnly || protected,
                  onChanged: (_) => edit(),
                  onSubmitted: (_) => session.commit(draft),
                  errorText: draft.error == null
                      ? null
                      : draft.detail ?? l.wsPropertyInvalid,
                ),
                BusyMarkGroupedTextEntry(
                  label: '${l.wsNavigationDepth} (depth)',
                  controller: depth,
                  readOnly: widget.readOnly || protected,
                  onChanged: (_) => edit(),
                  onSubmitted: (_) => session.commit(draft),
                ),
                Text('chapter, procedure, tab, def'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyTextEntry extends StatefulWidget {
  const _PropertyTextEntry({
    super.key,
    required this.label,
    required this.value,
    required this.apply,
    this.session,
    this.readOnly = false,
    this.commitOnBlur = true,
    this.chooseFile,
    this.supportingText,
    this.help,
  });
  final String label, value;
  final bool Function(String) apply;
  final WritersidePropertySession? session;
  final bool readOnly;
  final bool commitOnBlur;
  final Future<String?> Function()? chooseFile;
  final String? supportingText;
  final String? help;
  @override
  State<_PropertyTextEntry> createState() => _PropertyTextEntryState();
}

class _PropertyTextEntryState extends State<_PropertyTextEntry> {
  late final _localSession = WritersidePropertySession();
  WritersidePropertySession get _session => widget.session ?? _localSession;
  late WritersidePropertyDraft _draft;
  late final TextEditingController _controller;
  final _focus = FocusNode();
  String get _key => widget.key.toString();
  var _choosing = false;

  Future<void> _chooseFile() async {
    if (_choosing || !_session.flush()) return;
    final draft = _draft;
    setState(() => _choosing = true);
    try {
      // A successful flush can reparse the same element. Capture its refreshed
      // transaction after the workspace has rebuilt, before opening the dialog.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !identical(draft, _draft) || widget.readOnly) return;
      final apply = draft.apply;
      final chooser = widget.chooseFile;
      if (chooser == null) return;
      final selected = await chooser();
      if (!mounted ||
          selected == null ||
          !identical(draft, _draft) ||
          widget.readOnly) {
        return;
      }
      // Keep the authoritative target captured before opening the chooser.
      // A presentation rebuild may rebind this field while the dialog is open.
      draft.apply = apply;
      _session.edit(draft, selected);
      _session.commit(draft);
    } on Exception {
      if (mounted && identical(draft, _draft)) {
        _session.reject(WritersidePropertyRejection.unresolved);
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _draft = _session.bind(_key, widget.value, widget.apply);
    _controller = TextEditingController(text: _draft.text)
      ..addListener(_controllerChanged);
    _session.addListener(_refresh);
    _focus.addListener(_focusChanged);
  }

  void _refresh() {
    if (!mounted) return;
    if (_controller.text != _draft.text) _controller.text = _draft.text;
    setState(() {});
  }

  void _controllerChanged() {
    if (_controller.text != _draft.text) {
      _session.edit(_draft, _controller.text);
      if (mounted) setState(() {});
    }
  }

  void _focusChanged() {
    if (!_focus.hasFocus && widget.commitOnBlur) _session.commit(_draft);
  }

  @override
  void didUpdateWidget(covariant _PropertyTextEntry old) {
    super.didUpdateWidget(old);
    _draft = _session.bind(_key, widget.value, widget.apply);
    if (_controller.text != _draft.text) _controller.text = _draft.text;
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    _controller.removeListener(_controllerChanged);
    _controller.dispose();
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _localSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error =
        _draft.detail ??
        switch (_draft.error) {
          WritersidePropertyRejection.invalid => l.wsPropertyInvalid,
          WritersidePropertyRejection.readOnly => l.wsPropertiesReadOnly,
          WritersidePropertyRejection.stale => l.wsPropertiesConflict,
          WritersidePropertyRejection.unresolved => l.wsPropertiesUnresolved,
          null => null,
        };
    final field = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _RevertPropertyIntent(),
      },
      child: Actions(
        actions: {
          _RevertPropertyIntent: CallbackAction<_RevertPropertyIntent>(
            onInvoke: (_) {
              _session.revert(_draft);
              return null;
            },
          ),
        },
        child: BusyMarkGroupedTextEntry(
          readOnly: widget.readOnly,
          label: widget.label,
          controller: _controller,
          focusNode: _focus,
          errorText: error,
          trailing: widget.chooseFile == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BusyMarkHeaderIconButton(
                      icon: BusyMarkGlyphs.folderOpen,
                      tooltip: l.open,
                      onPressed: widget.readOnly || _choosing
                          ? null
                          : _chooseFile,
                    ),
                    if (_draft.text.isNotEmpty)
                      BusyMarkHeaderIconButton(
                        icon: BusyMarkGlyphs.windowClose,
                        tooltip: l.removeAction,
                        onPressed: widget.readOnly || _choosing
                            ? null
                            : () {
                                _session.edit(_draft, '');
                                _session.commit(_draft);
                              },
                      ),
                  ],
                ),
          onSubmitted: (_) => _session.commit(_draft),
          onChanged: (text) {
            _session.edit(_draft, text);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    final unit = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (widget.supportingText != null && _controller.text.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: SelectableText(
              widget.supportingText!,
              key: widget.label.endsWith('(id)')
                  ? const ValueKey('writerside-generated-anchor')
                  : ValueKey('writerside-property-support-${widget.label}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
    return widget.help == null
        ? unit
        : _PropertyContextHelp(help: widget.help!, child: unit);
  }
}

/// Existing tooltip treatment, available from the keyboard and in semantics.
class _PropertyContextHelp extends StatefulWidget {
  const _PropertyContextHelp({
    required this.help,
    required this.child,
    this.mergeSemantics = false,
  });
  final String help;
  final Widget child;
  final bool mergeSemantics;
  @override
  State<_PropertyContextHelp> createState() => _PropertyContextHelpState();
}

class _PropertyContextHelpState extends State<_PropertyContextHelp> {
  final _tooltip = GlobalKey<TooltipState>();
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.f1): () =>
          _tooltip.currentState?.ensureTooltipVisible(),
    },
    child: Tooltip(
      key: _tooltip,
      message: widget.help,
      excludeFromSemantics: true,
      child: widget.mergeSemantics
          ? MergeSemantics(
              child: Semantics(hint: widget.help, child: widget.child),
            )
          : Semantics(hint: widget.help, child: widget.child),
    ),
  );
}

class _RevertPropertyIntent extends Intent {
  const _RevertPropertyIntent();
}
