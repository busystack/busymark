import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
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
              tooltip: 'Unordered list',
              icon: Icons.format_list_bulleted,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.unorderedList),
            ),
            _button(
              context,
              tooltip: 'Ordered list',
              icon: Icons.format_list_numbered,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.orderedList),
            ),
            _button(
              context,
              tooltip: 'Task list',
              icon: Icons.check_box_outlined,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.taskList),
            ),
            _button(
              context,
              tooltip: 'Toggle task checked',
              icon: Icons.check_box,
              onPressed: onToggleTaskCommand,
            ),
            _button(
              context,
              tooltip: 'Indent list item',
              icon: Icons.format_indent_increase,
              onPressed: onIndentCommand,
            ),
            _button(
              context,
              tooltip: 'Outdent list item',
              icon: Icons.format_indent_decrease,
              onPressed: onOutdentCommand,
            ),
            _button(
              context,
              tooltip: 'Blockquote',
              icon: Icons.format_quote_outlined,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.blockquote),
            ),
            _button(
              context,
              tooltip: 'Code block',
              icon: Icons.code,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.codeBlock),
            ),
            _button(
              context,
              tooltip: 'Code block language',
              icon: Icons.data_object,
              onPressed: onCodeLanguageCommand,
            ),
            _button(
              context,
              tooltip: 'Image',
              icon: Icons.image_outlined,
              onPressed: onImageCommand,
            ),
            _button(
              context,
              tooltip: 'Inline image',
              icon: Icons.add_photo_alternate_outlined,
              onPressed: onInlineImageCommand,
            ),
            _button(
              context,
              tooltip: 'Table',
              icon: Icons.table_chart_outlined,
              onPressed: onTableCommand,
            ),
            _button(
              context,
              tooltip: 'Thematic break',
              icon: Icons.horizontal_rule,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.thematicBreak),
            ),
          ],
          [
            _button(
              context,
              tooltip: 'Bold',
              icon: Icons.format_bold,
              shortcut: 'Ctrl+B',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.bold),
            ),
            _button(
              context,
              tooltip: 'Italic',
              icon: Icons.format_italic,
              shortcut: 'Ctrl+I',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.italic),
            ),
            _button(
              context,
              tooltip: 'Underline',
              icon: Icons.format_underlined,
              shortcut: 'Ctrl+U',
              onPressed: () =>
                  onInlineCommand(BusyWysiwygInlineCommand.underline),
            ),
            _button(
              context,
              tooltip: 'Strikethrough',
              icon: Icons.format_strikethrough,
              shortcut: 'Alt+Shift+5',
              onPressed: () =>
                  onInlineCommand(BusyWysiwygInlineCommand.strikethrough),
            ),
            _button(
              context,
              tooltip: 'Inline code',
              icon: Icons.code_outlined,
              shortcut: 'Ctrl+E',
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.code),
            ),
            _button(
              context,
              tooltip: 'Link',
              icon: Icons.link,
              shortcut: 'Ctrl+K',
              onPressed: onLinkCommand,
            ),
            _button(
              context,
              tooltip: 'Hard line break',
              icon: Icons.keyboard_return,
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
      tooltip: 'Text style',
      icon: Icons.text_fields,
      foregroundColor: colorScheme.onPrimary,
      backgroundColor: _toolbarButtonBackground(context),
      boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.paragraph,
          label: 'Paragraph',
          icon: Icons.subject,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading1,
          label: 'Heading 1',
          icon: Icons.title,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading2,
          label: 'Heading 2',
          icon: Icons.title,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading3,
          label: 'Heading 3',
          icon: Icons.title,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading4,
          label: 'Heading 4',
          icon: Icons.title,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading5,
          label: 'Heading 5',
          icon: Icons.title,
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading6,
          label: 'Heading 6',
          icon: Icons.title,
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
