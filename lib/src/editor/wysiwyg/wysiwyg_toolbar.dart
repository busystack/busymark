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
  });

  final ValueChanged<BusyWysiwygBlockCommand> onBlockCommand;
  final ValueChanged<BusyWysiwygInlineCommand> onInlineCommand;
  final VoidCallback onLinkCommand;
  final VoidCallback onImageCommand;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.view,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: SingleChildScrollView(
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
                onPressed: () =>
                    onBlockCommand(BusyWysiwygBlockCommand.taskList),
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
                tooltip: 'Image',
                icon: Icons.image_outlined,
                onPressed: onImageCommand,
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
                onPressed: () =>
                    onInlineCommand(BusyWysiwygInlineCommand.italic),
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
            ],
          ]),
        ),
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
      ],
      onSelected: onBlockCommand,
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
    );
  }
}
