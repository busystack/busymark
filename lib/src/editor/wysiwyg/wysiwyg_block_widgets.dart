import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_inline_controller.dart';

class BusyMarkWysiwygBlockField extends StatelessWidget {
  const BusyMarkWysiwygBlockField({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onFocused,
  });

  final BusyBlock block;
  final BusyMarkWysiwygTextController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocused;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final style = _textStyle(context);
    final prefix = _prefix(context);
    final readOnly = _readOnly;
    return Padding(
      padding: _padding,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: readOnly ? null : _focusBlock,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _background(context),
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            border: _border(context),
          ),
          child: Padding(
            padding: _contentPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _minimumHeight(context)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prefix != null) ...[
                    SizedBox(width: 30, child: prefix),
                    const SizedBox(width: BusyMarkSpacing.sm),
                  ],
                  Expanded(
                    child: readOnly
                        ? SelectableText(
                            block.rawSource ?? block.plainText,
                            style: style.copyWith(
                              color: colors.mutedForeground,
                              fontFamily: 'Ubuntu Mono',
                            ),
                          )
                        : TextField(
                            controller: controller,
                            focusNode: focusNode,
                            maxLines: null,
                            minLines: 1,
                            style: style,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hoverColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: onFocused,
                            onChanged: onChanged,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _focusBlock() {
    onFocused();
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    if (!controller.selection.isValid || controller.selection.baseOffset < 0) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  double _minimumHeight(BuildContext context) {
    final style = _textStyle(context);
    final fontSize =
        style.fontSize ??
        Theme.of(context).textTheme.bodyMedium?.fontSize ??
        14;
    return switch (block.kind) {
      BusyBlockKind.heading => fontSize * 1.8,
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => fontSize * 2.4,
      _ => fontSize * 1.7,
    };
  }

  bool get _readOnly {
    return block.preserveRaw ||
        block.kind == BusyBlockKind.thematicBreak ||
        block.kind == BusyBlockKind.table;
  }

  EdgeInsets get _padding {
    return switch (block.kind) {
      BusyBlockKind.heading => const EdgeInsets.only(top: 16, bottom: 6),
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.symmetric(vertical: 8),
      _ => const EdgeInsets.symmetric(vertical: 4),
    };
  }

  EdgeInsets get _contentPadding {
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.all(12),
      _ => EdgeInsets.zero,
    };
  }

  TextStyle _textStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final level = int.tryParse(block.attributes['level'] ?? '') ?? 0;
    return switch (block.kind) {
      BusyBlockKind.heading when level == 1 => theme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 2 => theme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading => theme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.codeBlock => theme.bodyMedium!.copyWith(
        fontFamily: 'Ubuntu Mono',
        height: 1.45,
      ),
      _ => theme.bodyMedium!.copyWith(height: 1.5),
    };
  }

  Widget? _prefix(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.mutedForeground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Icon(Icons.circle, size: 6, color: colors.mutedForeground),
      ),
      BusyBlockKind.orderedListItem => Text(
        block.attributes['marker'] ?? '1.',
        textAlign: TextAlign.right,
        style: style,
      ),
      BusyBlockKind.taskListItem => Icon(
        block.attributes['task'] == 'true'
            ? Icons.check_box_outlined
            : Icons.check_box_outline_blank,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.image => Icon(
        Icons.image_outlined,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.blockquote => Icon(
        Icons.format_quote_outlined,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.codeBlock => Icon(
        Icons.code,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.writersideAdmonition => Icon(
        Icons.info_outline,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.thematicBreak => Divider(
        height: 20,
        color: colors.subtleBorder,
      ),
      _ => null,
    };
  }

  Color _background(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => colors.panel,
      _ => Colors.transparent,
    };
  }

  BoxBorder? _border(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => Border.all(color: colors.subtleBorder),
      _ => null,
    };
  }
}
