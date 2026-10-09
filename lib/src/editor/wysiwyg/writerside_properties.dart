import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../markdown/busymark_document.dart';
import '../../writerside/writerside_schema.dart';
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
      'tldr' => context.l10n.wsTldr,
      'include' => context.l10n.wsIncludeContent,
      'video' => context.l10n.video,
      _ => switch (block.kind) {
        BusyBlockKind.heading =>
          block.attributes['level'] == '1'
              ? context.l10n.topic
              : context.l10n.chapter,
        BusyBlockKind.codeBlock => context.l10n.codeBlock,
        BusyBlockKind.blockquote ||
        BusyBlockKind.writersideAdmonition => context.l10n.admonition,
        _ => context.l10n.paragraph,
      },
    };

/// Subordinate, non-modal authoring properties. Targets are supplied by the
/// editor, never inferred from whichever property entry happens to have focus.
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
    this.inlineTarget,
    this.onInlineProperty,
    this.videoDraft = false,
    this.onInsertVideo,
  });
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
    final tag = block == null
        ? ''
        : block.kind == BusyBlockKind.heading && !document.isXmlTopic
        ? block.attributes['level'] == '1'
              ? 'topic'
              : 'chapter'
        : WritersideEditingAdapter.tagForBlock(block);
    final attrs = block?.attributes ?? const <String, String>{};
    Widget entry(
      String attribute,
      String label, {
      String? value,
      bool topic = false,
      bool inline = false,
    }) => _PropertyTextEntry(
      key: ValueKey(
        'writerside-property-${topic ? 'topic' : block?.id}-$attribute',
      ),
      label: label,
      value: value ?? attrs[attribute] ?? '',
      apply: (value) => inline
          ? onInlineProperty?.call(attribute, value) ?? false
          : topic
          ? onTopicProperty(attribute, value)
          : onProperty(attribute, value),
    );
    Widget stateRow() {
      final value = attrs['default-state'] ?? 'collapsed';
      final values = WritersideSchema.valuesFor(tag, 'default-state').toList();
      return BusyMarkComboRow<String>(
        title: l.wsPublishedState,
        values: values.contains(value) ? values : [value, ...values],
        selected: value,
        labelFor: (v) => switch (v) {
          'expanded' => l.wsExpanded,
          'collapsed' => l.wsCollapsed,
          _ => v,
        },
        onSelected: (v) => onProperty('default-state', v),
        width: 120,
      );
    }

    final ancestors = path
        .where(
          (b) =>
              busyMarkIsWritersideContainer(b) ||
              b.kind == BusyBlockKind.heading ||
              b.id == block?.id,
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
          label: l.source,
          value: '',
          apply: (v) => onInsertVideo?.call(v) ?? false,
        ),
      );
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
      rows.add(
        entry(
          'for',
          l.wsNavigationElements,
          value: navigation?.attributes['for'] ?? '',
          topic: true,
        ),
      );
      rows.add(
        entry(
          'depth',
          l.wsNavigationDepth,
          value: navigation?.attributes['depth'] ?? '',
          topic: true,
        ),
      );
    } else if (block != null) {
      if (block.kind == BusyBlockKind.heading) {
        rows.add(
          _PropertyTextEntry(
            key: ValueKey('writerside-heading-title-${block.id}'),
            label: tag == 'topic' ? l.topicTitle : l.wsTitle,
            value: block.plainText,
            apply: onHeadingText,
          ),
        );
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
        rows.add(
          BusyMarkSwitchRow(
            title: l.wsCollapsible,
            value: busyMarkWritersideIsCollapsible(attrs),
            onChanged: (v) => onProperty('collapsible', v ? 'true' : 'false'),
          ),
        );
        // A definition item owns its published initial state. List collapse
        // is not an interchangeable property of the current paragraph/item.
        if (tag != 'deflist') rows.add(stateRow());
      }
      if (tag == 'def') rows.add(stateRow());
      if (tag == 'code-block') {
        rows.add(entry('language', l.language));
        rows.add(entry('collapsed-title', l.wsCollapsedTitle));
        rows.add(entry('src', l.source));
      }
      if (tag == 'deflist') {
        final value = attrs['type'] ?? 'full';
        final allowed = WritersideSchema.valuesFor('deflist', 'type').toList();
        rows.add(
          BusyMarkComboRow<String>(
            title: l.wsListLayout,
            values: allowed.contains(value) ? allowed : [value, ...allowed],
            selected: value,
            labelFor: (v) => switch (v) {
              'full' => l.wsFullLayout,
              'medium' => l.wsMediumLayout,
              'narrow' => l.wsNarrowLayout,
              _ => v,
            },
            onSelected: (v) => onProperty('type', v),
            width: 110,
          ),
        );
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
              l.wsListLayout,
              value: inline.attributes['force-layout'] ?? '',
              inline: true,
            ),
          );
        }
      }
      if ({'tabs', 'procedure', 'deflist'}.contains(tag)) {
        rows.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BusyMarkHeaderIconButton(
              icon: BusyMarkGlyphs.add,
              tooltip: l.wsAddItem,
              onPressed: () => onManageItem(null, null, false),
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
                  onPressed: () => onManageItem(item.id, -1, false),
                ),
                BusyMarkHeaderIconButton(
                  icon: BusyMarkGlyphs.downArrow,
                  tooltip: l.moveSectionDown,
                  onPressed: () => onManageItem(item.id, 1, false),
                ),
                BusyMarkHeaderIconButton(
                  icon: BusyMarkGlyphs.delete,
                  tooltip: l.removeAction,
                  onPressed:
                      block.children
                              .where((b) => b.attributes['element'] == itemTag)
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
                      topicSelected
                          ? l.wsTopicProperties
                          : l.wsElementProperties,
                      style: busyMarkSectionHeaderStyle(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BusyMarkHeaderIconButton(
                    icon: BusyMarkGlyphs.windowClose,
                    tooltip: l.close,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    BusyMarkGroupedList(
                      filled: true,
                      children: [
                        BusyMarkComboRow<String>(
                          title: videoDraft
                              ? l.video
                              : topicSelected
                              ? l.topic
                              : block == null
                              ? l.wsElementProperties
                              : writersideElementLabel(context, block),
                          values: values,
                          selected: selected,
                          labelFor: (id) => id == '@topic'
                              ? l.wsTopicProperties
                              : (() {
                                  final b = path
                                      .where((b) => b.id == id)
                                      .firstOrNull;
                                  return b == null
                                      ? l.wsElementProperties
                                      : '${writersideElementLabel(context, b)}${b.plainText.isEmpty ? '' : ' · ${b.plainText}'}';
                                })(),
                          onSelected: onTargetSelected,
                          width: 160,
                        ),
                      ],
                    ),
                    if (rows.isNotEmpty)
                      BusyMarkGroupedList(filled: true, children: rows),
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
  });
  final String label, value;
  final bool Function(String) apply;
  @override
  State<_PropertyTextEntry> createState() => _PropertyTextEntryState();
}

class _PropertyTextEntryState extends State<_PropertyTextEntry> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final _focus = FocusNode();
  bool _invalid = false;
  @override
  void didUpdateWidget(covariant _PropertyTextEntry old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != old.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply() {
    final accepted =
        _controller.text == widget.value || widget.apply(_controller.text);
    if (mounted) setState(() => _invalid = !accepted);
  }

  @override
  Widget build(BuildContext context) => BusyMarkGroupedTextEntry(
    label: widget.label,
    controller: _controller,
    focusNode: _focus,
    errorText: _invalid ? context.l10n.wsPropertyInvalid : null,
    onSubmitted: (_) => _apply(),
    onChanged: (_) {
      if (_invalid) setState(() => _invalid = false);
    },
    trailing: BusyMarkHeaderIconButton(
      icon: BusyMarkGlyphs.check,
      tooltip: context.l10n.apply,
      onPressed: _apply,
    ),
  );
}
