import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_commands.dart';

class BusyMarkWysiwygToolbar extends StatelessWidget {
  const BusyMarkWysiwygToolbar({
    super.key,
    required this.onBlockCommand,
    this.onAdmonitionCommand,
    required this.onInlineCommand,
    required this.onLinkCommand,
    required this.onInlineMathCommand,
    required this.onDisplayMathCommand,
    required this.onImageCommand,
    required this.onInlineImageCommand,
    required this.onTableCommand,
    required this.onHtmlCommand,
    required this.onIndentCommand,
    required this.onOutdentCommand,
    required this.onToggleTaskCommand,
    required this.onHardBreakCommand,
    this.isBlockCommandEnabled,
    this.admonitionCommandsEnabled = true,
    this.inlineCommandsEnabled = true,
    this.admonitionsEnabled = false,
    this.alignEnd = false,
    this.axis = Axis.horizontal,
  });

  final ValueChanged<BusyWysiwygBlockCommand> onBlockCommand;
  final ValueChanged<BusyAdmonitionStyle>? onAdmonitionCommand;
  final ValueChanged<BusyWysiwygInlineCommand> onInlineCommand;
  final VoidCallback onLinkCommand;
  final VoidCallback onInlineMathCommand;
  final VoidCallback onDisplayMathCommand;
  final VoidCallback onImageCommand;
  final VoidCallback onInlineImageCommand;
  final VoidCallback onTableCommand;
  final VoidCallback onHtmlCommand;
  final VoidCallback onIndentCommand;
  final VoidCallback onOutdentCommand;
  final VoidCallback onToggleTaskCommand;
  final VoidCallback onHardBreakCommand;
  final bool Function(BusyWysiwygBlockCommand command)? isBlockCommandEnabled;
  final bool admonitionCommandsEnabled;
  final bool inlineCommandsEnabled;
  final bool admonitionsEnabled;
  final bool alignEnd;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return SingleChildScrollView(
      scrollDirection: axis,
      reverse: alignEnd,
      clipBehavior: Clip.none,
      hitTestBehavior: HitTestBehavior.deferToChild,
      padding: axis == Axis.horizontal
          ? const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            )
          : const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.xs,
              vertical: BusyMarkSpacing.sm,
            ),
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        spacing: BusyMarkSpacing.xs,
        children: _groups(axis, [
          [
            _blockStyleMenu(context),
            _button(
              context,
              tooltip: context.l10n.bold,
              icon: BusyMarkGlyphs.bold,
              shortcut: BusyMarkEditorShortcutLabels.bold,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.bold)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.italic,
              icon: BusyMarkGlyphs.italic,
              shortcut: BusyMarkEditorShortcutLabels.italic,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.italic)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.underline,
              icon: BusyMarkGlyphs.underline,
              shortcut: BusyMarkEditorShortcutLabels.underline,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.underline)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.strikethrough,
              icon: BusyMarkGlyphs.strikethrough,
              shortcut: BusyMarkEditorShortcutLabels.strikethrough,
              onPressed: inlineCommandsEnabled
                  ? () =>
                        onInlineCommand(BusyWysiwygInlineCommand.strikethrough)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineCode,
              icon: BusyMarkGlyphs.code,
              shortcut: BusyMarkEditorShortcutLabels.inlineCode,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.code)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.link,
              icon: BusyMarkGlyphs.link,
              shortcut: BusyMarkEditorShortcutLabels.link,
              onPressed: inlineCommandsEnabled ? onLinkCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineMath,
              icon: BusyMarkGlyphs.math,
              onPressed: inlineCommandsEnabled ? onInlineMathCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.hardLineBreak,
              icon: BusyMarkGlyphs.hardBreak,
              shortcut: BusyMarkEditorShortcutLabels.hardLineBreak,
              onPressed: inlineCommandsEnabled ? onHardBreakCommand : null,
            ),
          ],
          [
            if (admonitionsEnabled && onAdmonitionCommand != null)
              _admonitionMenu(context),
            _button(
              context,
              tooltip: context.l10n.blockquote,
              icon: BusyMarkGlyphs.blockquote,
              shortcut: BusyMarkEditorShortcutLabels.blockquote,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.blockquote)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.blockquote)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.codeBlock,
              icon: BusyMarkGlyphs.codeBlock,
              shortcut: BusyMarkEditorShortcutLabels.codeBlock,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.codeBlock)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.codeBlock)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.displayMath,
              icon: BusyMarkGlyphs.math,
              onPressed: onDisplayMathCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.htmlBlock,
              icon: BusyMarkGlyphs.htmlBlock,
              onPressed: onHtmlCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.thematicBreak,
              icon: BusyMarkGlyphs.thematicBreak,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.thematicBreak)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.thematicBreak)
                  : null,
            ),
          ],
          [
            _button(
              context,
              tooltip: context.l10n.unorderedList,
              icon: BusyMarkGlyphs.unorderedList,
              shortcut: BusyMarkEditorShortcutLabels.unorderedList,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.unorderedList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.unorderedList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.orderedList,
              icon: BusyMarkGlyphs.orderedList,
              shortcut: BusyMarkEditorShortcutLabels.orderedList,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.orderedList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.orderedList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.taskList,
              icon: BusyMarkGlyphs.checkedBox,
              shortcut: BusyMarkEditorShortcutLabels.taskList,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.taskList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.taskList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.toggleTaskChecked,
              icon: BusyMarkGlyphs.checkedBox,
              onPressed: onToggleTaskCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.indentListItem,
              icon: BusyMarkGlyphs.indentFor(direction),
              shortcut: BusyMarkEditorShortcutLabels.indent,
              onPressed: onIndentCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.outdentListItem,
              icon: BusyMarkGlyphs.outdentFor(direction),
              shortcut: BusyMarkEditorShortcutLabels.outdent,
              onPressed: onOutdentCommand,
            ),
          ],
          [
            _button(
              context,
              tooltip: context.l10n.image,
              icon: BusyMarkGlyphs.image,
              shortcut: BusyMarkEditorShortcutLabels.image,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.image)
                  ? onImageCommand
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineImage,
              icon: BusyMarkGlyphs.inlineImage,
              onPressed: inlineCommandsEnabled ? onInlineImageCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.table,
              icon: BusyMarkGlyphs.table,
              onPressed: onTableCommand,
            ),
          ],
        ]),
      ),
    );
  }

  bool _blockCommandEnabled(BusyWysiwygBlockCommand command) {
    return isBlockCommandEnabled?.call(command) ?? true;
  }

  List<Widget> _groups(Axis axis, List<List<Widget>> groups) {
    final widgets = <Widget>[];
    for (final (groupIndex, group)
        in groups.where((items) => items.isNotEmpty).indexed) {
      if (widgets.isNotEmpty) {
        widgets.add(
          SizedBox(
            key: ValueKey('wysiwyg-toolbar-group-separator-$groupIndex'),
            width: axis == Axis.horizontal ? BusyMarkSpacing.sm : null,
            height: axis == Axis.vertical ? BusyMarkSpacing.sm : null,
          ),
        );
      }
      widgets.addAll(group);
    }
    return widgets;
  }

  Widget _blockStyleMenu(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<BusyWysiwygBlockCommand>(
      tooltip: context.l10n.textStyle,
      icon: BusyMarkGlyphs.font,
      shortcut: BusyMarkEditorShortcutLabels.textStyle,
      transparent: false,
      elevated: true,
      foregroundColor: BusyMarkLinuxPalette.white,
      backgroundColor: _editorToolbarButtonBackground(context),
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.paragraph,
          label: context.l10n.paragraph,
          icon: BusyMarkGlyphs.paragraph,
          shortcut: BusyMarkEditorShortcutLabels.paragraph,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.paragraph),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading1,
          label: context.l10n.heading1,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading1,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading1),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading2,
          label: context.l10n.heading2,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading2,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading2),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading3,
          label: context.l10n.heading3,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading3,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading3),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading4,
          label: context.l10n.heading4,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading4,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading4),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading5,
          label: context.l10n.heading5,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading5,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading5),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading6,
          label: context.l10n.heading6,
          icon: BusyMarkGlyphs.heading,
          shortcut: BusyMarkEditorShortcutLabels.heading6,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading6),
        ),
      ],
      onSelected: onBlockCommand,
    );
  }

  Widget _admonitionMenu(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<BusyAdmonitionStyle>(
      tooltip: context.l10n.admonition,
      icon: BusyMarkGlyphs.info,
      transparent: false,
      elevated: true,
      foregroundColor: BusyMarkLinuxPalette.white,
      backgroundColor: _editorToolbarButtonBackground(context),
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyAdmonitionStyle.tip,
          label: context.l10n.tip,
          icon: BusyMarkGlyphs.tip,
          enabled: admonitionCommandsEnabled,
        ),
        BusyMarkPopupMenuItem(
          value: BusyAdmonitionStyle.note,
          label: context.l10n.note,
          icon: BusyMarkGlyphs.info,
          enabled: admonitionCommandsEnabled,
        ),
        BusyMarkPopupMenuItem(
          value: BusyAdmonitionStyle.warning,
          label: context.l10n.warning,
          icon: BusyMarkGlyphs.warning,
          enabled: admonitionCommandsEnabled,
        ),
        BusyMarkPopupMenuItem(
          value: BusyAdmonitionStyle.quote,
          label: context.l10n.quote,
          icon: BusyMarkGlyphs.blockquote,
          enabled: admonitionCommandsEnabled,
        ),
      ],
      onSelected: onAdmonitionCommand!,
    );
  }

  Widget _button(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    String? shortcut,
  }) {
    return BusyMarkHeaderIconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      shortcut: shortcut,
      transparent: false,
      elevated: true,
      foregroundColor: BusyMarkLinuxPalette.white,
      backgroundColor: _editorToolbarButtonBackground(context),
    );
  }

  WidgetStateProperty<Color?> _editorToolbarButtonBackground(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return colors.disabledControl;
      }
      return theme.colorScheme.primary;
    });
  }
}
