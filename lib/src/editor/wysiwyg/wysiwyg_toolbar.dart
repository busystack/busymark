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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: BusyMarkSpacing.sm,
        vertical: BusyMarkSpacing.xs,
      ),
      child: Row(
        spacing: BusyMarkSpacing.xs,
        children: _groups([
          [_blockStyleMenu()],
          [
            _button(
              tooltip: 'Unordered list',
              icon: Icons.format_list_bulleted,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.unorderedList),
            ),
            _button(
              tooltip: 'Ordered list',
              icon: Icons.format_list_numbered,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.orderedList),
            ),
            _button(
              tooltip: 'Task list',
              icon: Icons.check_box_outlined,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.taskList),
            ),
            _button(
              tooltip: 'Toggle task checked',
              icon: Icons.check_box,
              onPressed: onToggleTaskCommand,
            ),
            _button(
              tooltip: 'Indent list item',
              icon: Icons.format_indent_increase,
              onPressed: onIndentCommand,
            ),
            _button(
              tooltip: 'Outdent list item',
              icon: Icons.format_indent_decrease,
              onPressed: onOutdentCommand,
            ),
            _button(
              tooltip: 'Blockquote',
              icon: Icons.format_quote_outlined,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.blockquote),
            ),
            _button(
              tooltip: 'Code block',
              icon: Icons.code,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.codeBlock),
            ),
            _button(
              tooltip: 'Code block language',
              icon: Icons.data_object,
              onPressed: onCodeLanguageCommand,
            ),
            _button(
              tooltip: 'Image',
              icon: Icons.image_outlined,
              onPressed: onImageCommand,
            ),
            _button(
              tooltip: 'Inline image',
              icon: Icons.add_photo_alternate_outlined,
              onPressed: onInlineImageCommand,
            ),
            _button(
              tooltip: 'Table',
              icon: Icons.table_chart_outlined,
              onPressed: onTableCommand,
            ),
            _button(
              tooltip: 'Thematic break',
              icon: Icons.horizontal_rule,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.thematicBreak),
            ),
          ],
          [
            _button(
              tooltip: 'Bold',
              icon: Icons.format_bold,
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.bold),
            ),
            _button(
              tooltip: 'Italic',
              icon: Icons.format_italic,
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.italic),
            ),
            _button(
              tooltip: 'Strikethrough',
              icon: Icons.format_strikethrough,
              onPressed: () =>
                  onInlineCommand(BusyWysiwygInlineCommand.strikethrough),
            ),
            _button(
              tooltip: 'Inline code',
              icon: Icons.code_outlined,
              onPressed: () => onInlineCommand(BusyWysiwygInlineCommand.code),
            ),
            _button(
              tooltip: 'Link',
              icon: Icons.link,
              onPressed: onLinkCommand,
            ),
            _button(
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

  Widget _blockStyleMenu() {
    return BusyMarkHeaderPopupMenuButton<BusyWysiwygBlockCommand>(
      tooltip: 'Text style',
      icon: Icons.text_fields,
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
      transparent: true,
    );
  }

  Widget _button({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return BusyMarkHeaderIconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      transparent: true,
    );
  }
}
