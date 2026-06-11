import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import 'wysiwyg_commands.dart';

class BusyMarkWysiwygToolbar extends StatelessWidget {
  const BusyMarkWysiwygToolbar({
    super.key,
    required this.onBlockCommand,
    required this.onInlineCommand,
    required this.onLinkCommand,
  });

  final ValueChanged<BusyWysiwygBlockCommand> onBlockCommand;
  final ValueChanged<BusyWysiwygInlineCommand> onInlineCommand;
  final VoidCallback onLinkCommand;

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
          children: [
            _button(
              tooltip: 'Paragraph',
              icon: Icons.subject,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.paragraph),
            ),
            _button(
              tooltip: 'Heading 1',
              icon: Icons.title,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.heading1),
            ),
            _button(
              tooltip: 'Heading 2',
              icon: Icons.text_fields,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.heading2),
            ),
            _button(
              tooltip: 'Heading 3',
              icon: Icons.short_text,
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.heading3),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
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
              onPressed: () => onBlockCommand(BusyWysiwygBlockCommand.image),
            ),
            _button(
              tooltip: 'Thematic break',
              icon: Icons.horizontal_rule,
              onPressed: () =>
                  onBlockCommand(BusyWysiwygBlockCommand.thematicBreak),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
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
          ],
        ),
      ),
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
