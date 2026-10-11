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

String writersideElementLabel(BuildContext context, BusyBlock block) =>
    switch (block.attributes['element']) {
      'topic' => context.l10n.topic,
      'chapter' => context.l10n.chapter,
      'procedure' => context.l10n.procedure,
      'step' => context.l10n.wsStep,
      'tabs' => context.l10n.tabs,
      'tab' => context.l10n.tab,
      'deflist' => context.l10n.wsDefinitionList,
      'def' => context.l10n.wsTerm,
      'list' =>
        block.attributes['type'] == 'decimal'
            ? context.l10n.orderedList
            : context.l10n.unorderedList,
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
          block.attributes['level'] == '1'
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
    this.session,
    this.readOnly = false,
    this.onSourceLocation,
    this.onChooseInclude,
    this.onChooseCodeSource,
    this.inlineTarget,
    this.onInlineProperty,
    this.videoDraft = false,
    this.onInsertVideo,
  });
  final WritersideEffectiveProperties effectiveProperties;
  final WritersidePropertySession? session;
  final bool readOnly;
  final VoidCallback? onSourceLocation;
  final VoidCallback? onChooseInclude;
  final VoidCallback? onChooseCodeSource;
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
            : block.kind == BusyBlockKind.heading &&
                  !document.isXmlTopic &&
                  !block.attributes.containsKey('element')
            ? 'chapter'
            : WritersideEditingAdapter.tagForBlock(block));
    final attrs =
        inlineTarget?.attributes ??
        block?.attributes ??
        const <String, String>{};
    final immutable =
        readOnly ||
        block?.isSourceProtected == true ||
        block?.preserveRaw == true;
    final offered = <String>{};
    Widget resetOverride(String attribute) => BusyMarkHeaderIconButton(
      icon: BusyMarkGlyphs.windowClose,
      tooltip: l.wsUseDefault,
      onPressed: immutable
          ? null
          : () {
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
    }) {
      offered.add(attribute == 'language' ? 'lang' : attribute);
      return _PropertyTextEntry(
        key: ValueKey(
          'writerside-property-${topic ? 'topic' : block?.id}-$attribute',
        ),
        session: session,
        readOnly: immutable || !enabled,
        label: label,
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
    Widget dimension(String attribute, String label) => Row(
      children: [
        Expanded(child: entry(attribute, label, enabled: !externalImage)),
        if (externalImage && attrs[attribute]?.isNotEmpty == true)
          resetOverride(attribute),
      ],
    );
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
      final property = effectiveProperties.resolve(
        tag,
        attribute,
        attrs,
        definitionList: listAttributes,
      );
      final defaultProperty = effectiveProperties.resolve(
        tag,
        attribute,
        {...attrs}..remove(attribute),
        definitionList: listAttributes,
      );
      final value = attrs[attribute] ?? '';
      final allowed = WritersideSchema.valuesFor(tag, attribute).toList();
      final values = [
        '',
        ...allowed,
        if (value.isNotEmpty && !allowed.contains(value)) value,
      ];
      return Tooltip(
        message:
            '${property.origin.name}: ${property.value ?? l.wsPropertiesUnresolved}',
        child: Row(
          children: [
            Expanded(
              child: BusyMarkComboRow<String>(
                enabled: !immutable && active,
                subtitle: active ? null : l.wsPropertiesInactive,
                title: label,
                values: values,
                selected: value,
                labelFor: (v) => v.isEmpty
                    ? '${l.wsUseDefault} — ${defaultProperty.value == null ? l.wsPropertiesUnresolved : switch (defaultProperty.value) {
                              'expanded' => l.wsExpanded,
                              'collapsed' => l.wsCollapsed,
                              'inherited' => l.wsInherited,
                              'true' => l.wsEnabled,
                              'false' => l.wsDisabled,
                              'full' => l.wsFullLayout,
                              'medium' => l.wsMediumLayout,
                              'narrow' => l.wsNarrowLayout,
                              'compact' => l.wsCompactLayout,
                              'wide' => l.wsWideLayout,
                              _ => defaultProperty.value!,
                            }}'
                    : switch (v) {
                        'expanded' => l.wsExpanded,
                        'collapsed' => l.wsCollapsed,
                        'true' => l.wsEnabled,
                        'false' => l.wsDisabled,
                        'full' => l.wsFullLayout,
                        'medium' => l.wsMediumLayout,
                        'narrow' => l.wsNarrowLayout,
                        'compact' => l.wsCompactLayout,
                        'wide' => l.wsWideLayout,
                        _ => v,
                      },
                onSelected: (v) {
                  if (!immutable && (active || v.isEmpty)) {
                    if (inlineTarget != null) {
                      onInlineProperty?.call(attribute, v);
                    } else {
                      onProperty(attribute, v.isEmpty ? null : v);
                    }
                  }
                },
                width: 170,
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
              b.id == block?.id,
        )
        .where(
          (b) =>
              !(b.attributes['element'] == 'topic' ||
                  b.kind == BusyBlockKind.heading &&
                      b.attributes['level'] == '1' &&
                      !b.attributes.containsKey('element')),
        )
        .toList();
    final values = [
      '@topic',
      ...{for (final b in ancestors) b.id},
    ];
    final selected = topicSelected ? '@topic' : block?.id ?? '@topic';
    if (!values.contains(selected)) values.add(selected);
    final rows = <Widget>[];
    if (videoDraft) {
      rows.add(
        _PropertyTextEntry(
          key: const ValueKey('writerside-video-source'),
          commitOnBlur: false,
          session: session,
          readOnly: immutable,
          label: l.source,
          value: '',
          apply: (v) => onInsertVideo?.call(v) ?? false,
        ),
      );
    } else if (inlineTarget != null) {
      final selectedInline = inlineTarget!;
      switch (selectedInline.kind) {
        case BusyInlineKind.link:
          rows.add(entry('href', l.source, value: selectedInline.destination));
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
          rows.add(entry('origin', l.writerside));
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
          rows.add(entry('preview-src', l.videoPreview));
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
          rows.add(entry('key', l.keyboardShortcuts));
          rows.add(entry('from-keymap-of', l.source));
          rows.add(entry('force-layout', l.keyboardLayout));
        default:
          break;
      }
    } else if (topicSelected) {
      final root = document.blocks
          .where((b) => b.attributes['element'] == 'topic')
          .firstOrNull;
      BusyBlock? navigation;
      for (final b in root?.children ?? document.blocks) {
        if (b.attributes['element'] == 'show-structure') {
          navigation = b;
          break;
        }
      }
      if (block != null) {
        if (block.kind == BusyBlockKind.heading &&
            !document.isXmlTopic &&
            !block.attributes.containsKey('element')) {
          rows.add(
            _PropertyTextEntry(
              key: ValueKey('writerside-heading-title-${block.id}'),
              session: session,
              readOnly: immutable,
              label: l.topicTitle,
              value: block.plainText,
              apply: onHeadingText,
            ),
          );
        } else {
          rows.add(entry('title', l.topicTitle, value: attrs['title'] ?? ''));
        }
        rows.add(entry('id', l.wsIdentifier));
        if (!document.isXmlTopic) {
          rows.add(entry('title', l.wsTitleOverride));
          rows.add(entry('switcher-key', l.wsSwitcherKey));
        }
      }
      rows.add(
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
      final declarations = (root?.children ?? document.blocks)
          .where((b) => b.attributes['element'] == 'show-structure')
          .toList();
      final navigationEditable =
          declarations.length < 2 &&
          !declarations.any(
            (b) => b.attributes.keys.any(
              {'instance', 'filter', 'switcher-key'}.contains,
            ),
          );
      if (!navigationEditable) rows.add(Text(l.wsPropertiesProtected));
      rows.add(
        BusyMarkComboRow<String>(
          title: l.wsNavigationElements,
          values: const ['default', 'all', 'none', 'custom'],
          selected: navigation == null
              ? 'default'
              : navigation.attributes['for'] == 'none'
              ? 'none'
              : WritersideEditingAdapter.sourceAttributes(navigation).isEmpty
              ? 'all'
              : 'custom',
          enabled: !immutable && navigationEditable,
          labelFor: (v) => switch (v) {
            'default' => l.wsUseDefault,
            'all' => l.wsNavigationAll,
            'none' => l.wsNavigationNone,
            _ => l.wsNavigationCustom,
          },
          onSelected: (v) {
            if (v != 'custom') onTopicProperty('@navigation', v);
          },
          width: 150,
        ),
      );
      rows.add(
        entry(
          'for',
          l.wsNavigationElements,
          value: navigation?.attributes['for'] ?? '',
          topic: true,
          enabled: navigationEditable,
        ),
      );
      rows.add(
        entry(
          'depth',
          l.wsNavigationDepth,
          value: navigation?.attributes['depth'] ?? '',
          topic: true,
          enabled: navigationEditable,
        ),
      );
    } else if (block != null) {
      if (block.kind == BusyBlockKind.heading) {
        if (!document.isXmlTopic && !block.attributes.containsKey('element')) {
          rows.add(entry('title', l.wsTitleOverride));
          rows.add(
            _PropertyTextEntry(
              key: ValueKey('writerside-heading-title-${block.id}'),
              session: session,
              readOnly: immutable,
              label: tag == 'topic' ? l.topicTitle : l.wsTitle,
              value: block.plainText,
              apply: onHeadingText,
            ),
          );
        } else {
          rows.add(entry('title', l.wsTitle));
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
        rows.add(entry('id', l.wsIdentifier));
      }
      if ({'chapter', 'code-block', 'procedure', 'deflist'}.contains(tag)) {
        rows.add(enumRow('collapsible', l.wsCollapsible));
        rows.add(stateRow());
      }
      if (tag == 'def') rows.add(stateRow());
      if (tag == 'code-block') {
        rows.add(
          BusyMarkComboRow<String>(
            title: l.source,
            values: const ['inline', 'file'],
            selected: attrs['src']?.isNotEmpty == true ? 'file' : 'inline',
            enabled: !immutable && onChooseCodeSource != null,
            labelFor: (v) => v == 'inline' ? l.inlineCode : l.file,
            onSelected: (v) {
              if (v == 'inline') {
                onProperty('src', null);
              } else {
                onChooseCodeSource?.call();
              }
            },
            width: 150,
          ),
        );
        rows.add(entry('language', l.language));
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
        rows.add(entry('src', l.source));
        rows.add(entry('include-lines', l.wsIncludeLines));
        rows.add(entry('include-symbol', l.wsIncludeSymbol));
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
        rows.add(entry('preview-src', l.videoPreview));
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
        rows.add(entry('from', l.source));
        rows.add(entry('element-id', l.wsIdentifier));
        if (attrs.containsKey('origin')) {
          rows.add(entry('origin', l.writerside));
        }
        rows.add(entry('use-filter', l.wsFilter));
      }
      if (tag == 'video') {
        rows.add(entry('src', l.source));
        rows.add(entry('preview-src', l.videoPreview));
      }
      if (WritersideSchema.attributesFor(tag).contains('switcher-key') &&
          tag != 'topic') {
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
              l.keyboardShortcuts,
              value: inline.attributes['key'] ?? '',
              inline: true,
            ),
          );
          rows.add(
            entry(
              'from-keymap-of',
              l.source,
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
    final advanced = <Widget>[];
    if (block != null &&
        !videoDraft &&
        (inlineTarget == null || inlineTag != null)) {
      final properties =
          WritersideSchema.attributesFor(tag)
              .where(
                (a) =>
                    !offered.contains(a) &&
                    !(tag == 'deflist' &&
                        a == 'style' &&
                        !attrs.containsKey(a)) &&
                    !{'title', 'level'}.contains(a) &&
                    !(topicSelected &&
                        !document.isXmlTopic &&
                        {'collapsible', 'default-state'}.contains(a)) &&
                    !(tag == 'topic' &&
                        !document.isXmlTopic &&
                        a == 'is-library'),
              )
              .toList()
            ..sort();
      for (final name in properties) {
        final allowed = WritersideSchema.valuesFor(tag, name);
        advanced.add(
          allowed.isEmpty
              ? entry(name, name)
              : enumRow(
                  name,
                  name,
                  active: !(tag == 'def' && name == 'collapsible'),
                ),
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
                          ? l.wsPropertiesSelection
                          : '${writersideElementLabel(context, block)} · ${block.attributes['id'] ?? ''} · ${block.attributes['title'] ?? block.attributes['busymark-title-label'] ?? block.plainText}',
                      child: BusyMarkGroupedList(
                        filled: true,
                        children: [
                          BusyMarkComboRow<String>(
                            title: videoDraft
                                ? l.video
                                : topicSelected
                                ? l.topic
                                : block == null
                                ? l.wsElementProperties
                                : inlineTarget?.kind == BusyInlineKind.image
                                ? l.image
                                : inlineTarget?.kind == BusyInlineKind.link
                                ? l.link
                                : inlineTarget?.kind ==
                                      BusyInlineKind.writersideVariable
                                ? l.wsVariableReference
                                : inlineTarget?.kind ==
                                      BusyInlineKind.writersideShortcut
                                ? l.keyboardShortcuts
                                : writersideElementLabel(context, block),
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
                                        ? '${switch (inlineTarget!.kind) {
                                            BusyInlineKind.image => l.image,
                                            BusyInlineKind.link => l.link,
                                            BusyInlineKind.writersideVariable => l.wsVariableReference,
                                            _ => l.keyboardShortcuts,
                                          }} · ${block!.plainText.substring(inlineTarget!.start, inlineTarget!.end)}'
                                        : b == null
                                        ? l.wsElementProperties
                                        : '${writersideElementLabel(context, b)}${(b.attributes['busymark-title-label'] ?? b.plainText).isEmpty ? '' : ' · ${b.attributes['busymark-title-label'] ?? b.plainText}'}';
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
                    if (advanced.isNotEmpty)
                      Material(
                        color: BusyMarkSurfaceColors.of(context).panel,
                        child: ExpansionTile(
                          title: Text(l.advanced),
                          initiallyExpanded: false,
                          children: [
                            BusyMarkGroupedList(
                              filled: true,
                              children: advanced,
                            ),
                          ],
                        ),
                      ),
                    if (onSourceLocation != null)
                      TextButton(
                        onPressed: onSourceLocation,
                        child: Text(l.source),
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

class _PropertyTextEntry extends StatefulWidget {
  const _PropertyTextEntry({
    super.key,
    required this.label,
    required this.value,
    required this.apply,
    this.session,
    this.readOnly = false,
    this.commitOnBlur = true,
  });
  final String label, value;
  final bool Function(String) apply;
  final WritersidePropertySession? session;
  final bool readOnly;
  final bool commitOnBlur;
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
    return Shortcuts(
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
          onSubmitted: (_) => _session.commit(_draft),
          onChanged: (text) {
            _session.edit(_draft, text);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

class _RevertPropertyIntent extends Intent {
  const _RevertPropertyIntent();
}
