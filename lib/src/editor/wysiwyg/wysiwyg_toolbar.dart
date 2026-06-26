import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import 'wysiwyg_commands.dart';

class BusyMarkWysiwygToolbar extends StatelessWidget {
  const BusyMarkWysiwygToolbar({
    super.key,
    required this.onBlockCommand,
    required this.onInlineCommand,
    required this.onLinkCommand,
    required this.onImageCommand,
    required this.onInlineImageCommand,
    required this.onTableCommand,
    required this.onIndentCommand,
    required this.onOutdentCommand,
    required this.onToggleTaskCommand,
    required this.onHardBreakCommand,
    required this.onCodeLanguageCommand,
    this.alignEnd = false,
  });

  final ValueChanged<BusyWysiwygBlockCommand> onBlockCommand;
  final ValueChanged<BusyWysiwygInlineCommand> onInlineCommand;
  final VoidCallback onLinkCommand;
  final VoidCallback onImageCommand;
  final VoidCallback onInlineImageCommand;
  final VoidCallback onTableCommand;
  final VoidCallback onIndentCommand;
  final VoidCallback onOutdentCommand;
  final VoidCallback onToggleTaskCommand;
  final VoidCallback onHardBreakCommand;
  final VoidCallback onCodeLanguageCommand;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: alignEnd,
      padding: const EdgeInsets.symmetric(
        horizontal: BusyMarkSpacing.sm,
        vertical: BusyMarkSpacing.xs,
      ),
      child: Row(
        spacing: BusyMarkSpacing.xs,
        children: _groups([
          [_blockStyleMenu(context)],
          [
            _button(
              context,
              tooltip: context.l10n.unorderedList,
              icon: BusyMarkGlyphs.unorderedList,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.unorderedList),
            ),
            _button(
              context,
              tooltip: context.l10n.orderedList,
              icon: BusyMarkGlyphs.orderedList,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.orderedList),
            ),
            _button(
              context,
              tooltip: context.l10n.taskList,
              icon: BusyMarkGlyphs.checkedBox,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.taskList),
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
              icon: BusyMarkGlyphs.indent,
              onPressed: onIndentCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.outdentListItem,
              icon: BusyMarkGlyphs.outdent,
              onPressed: onOutdentCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.blockquote,
              icon: BusyMarkGlyphs.blockquote,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.blockquote),
            ),
            _button(
              context,
              tooltip: context.l10n.codeBlock,
              icon: BusyMarkGlyphs.code,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.codeBlock),
            ),
            _button(
              context,
              tooltip: context.l10n.codeBlockLanguage,
              icon: BusyMarkGlyphs.insertObject,
              onPressed: onCodeLanguageCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.image,
              icon: BusyMarkGlyphs.image,
              onPressed: onImageCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineImage,
              icon: BusyMarkGlyphs.inlineImage,
              onPressed: onInlineImageCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.table,
              icon: BusyMarkGlyphs.table,
              onPressed: onTableCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.thematicBreak,
              icon: BusyMarkGlyphs.thematicBreak,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.thematicBreak),
            ),
          ],
          [
            _button(
              context,
              tooltip: context.l10n.bold,
              icon: BusyMarkGlyphs.bold,
              shortcut: 'Ctrl+B',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.bold),
            ),
            _button(
              context,
              tooltip: context.l10n.italic,
              icon: BusyMarkGlyphs.italic,
              shortcut: 'Ctrl+I',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.italic),
            ),
            _button(
              context,
              tooltip: context.l10n.underline,
              icon: BusyMarkGlyphs.underline,
              shortcut: 'Ctrl+U',
              onPressed: () =>
                  onInlineCommand(BusyWysiwygInlineCommand.underline),
            ),
            _button(
              context,
              tooltip: context.l10n.strikethrough,
              icon: BusyMarkGlyphs.strikethrough,
              shortcut: 'Alt+Shift+5',
              onPressed: () =>
                  onInlineCommand(BusyWysiwygInlineCommand.strikethrough),
            ),
            _button(
              context,
              tooltip: context.l10n.inlineCode,
              icon: BusyMarkGlyphs.code,
              shortcut: 'Ctrl+E',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.code),
            ),
            _button(
              context,
              tooltip: context.l10n.link,
              icon: BusyMarkGlyphs.link,
              shortcut: 'Ctrl+K',
              onPressed: onLinkCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.hardLineBreak,
              icon: BusyMarkGlyphs.hardBreak,
              onPressed: onHardBreakCommand,
            ),
          ],
        ]),
      ),
    );
  }

  List<Widget> _groups(List<List<Widget>> groups) {
    final widgets = <Widget>[];
    for (final group in groups.where((items) => items.isNotEmpty)) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: BusyMarkSpacing.sm));
      }
      widgets.addAll(group);
    }
    return widgets;
  }

  Widget _blockStyleMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkHeaderPopupMenuButton<BusyWysiwygBlockCommand>(
      tooltip: context.l10n.textStyle,
      icon: BusyMarkGlyphs.font,
      foregroundColor: colorScheme.onPrimary,
      backgroundColor: _toolbarButtonBackground(context),
      boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.paragraph,
          label: context.l10n.paragraph,
          icon: BusyMarkGlyphs.paragraph,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading1,
          label: context.l10n.heading1,
          icon: BusyMarkGlyphs.heading,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading2,
          label: context.l10n.heading2,
          icon: BusyMarkGlyphs.heading,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading3,
          label: context.l10n.heading3,
          icon: BusyMarkGlyphs.heading,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading4,
          label: context.l10n.heading4,
          icon: BusyMarkGlyphs.heading,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading5,
          label: context.l10n.heading5,
          icon: BusyMarkGlyphs.heading,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading6,
          label: context.l10n.heading6,
          icon: BusyMarkGlyphs.heading,
        ),
      ],
      onSelected: onBlockCommand,
    );
  }

  Widget _button(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    String? shortcut,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkHeaderIconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      shortcut: shortcut,
      foregroundColor: colorScheme.onPrimary,
      backgroundColor: _toolbarButtonBackground(context),
      boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
    );
  }

  WidgetStateProperty<Color?> _toolbarButtonBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return colors.disabledControl;
      }
      if (states.contains(WidgetState.pressed)) {
        return Color.alphaBlend(
          colorScheme.onPrimary.withValues(alpha: 0.18),
          colorScheme.primary,
        );
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return Color.alphaBlend(
          colorScheme.onPrimary.withValues(alpha: 0.10),
          colorScheme.primary,
        );
      }
      return colorScheme.primary;
    });
  }
}
