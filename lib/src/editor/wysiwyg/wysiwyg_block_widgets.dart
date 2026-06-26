import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../markdown_image_view.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_inline_controller.dart';

class BusyMarkWysiwygBlockField extends StatelessWidget {
  const BusyMarkWysiwygBlockField({
    super.key,
    required this.block,
    required this.documentFilePath,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onTableCellChanged,
    required this.onTableRowInserted,
    required this.onTableRowDeleted,
    required this.onTableColumnInserted,
    required this.onTableColumnDeleted,
    required this.onTableDeleted,
    required this.onImageEditRequested,
    required this.onFocused,
    this.selected = false,
    this.selectionRange,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final BusyMarkWysiwygTextController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final void Function(String cellId, String text) onTableCellChanged;
  final void Function(int rowIndex, {required bool after}) onTableRowInserted;
  final ValueChanged<int> onTableRowDeleted;
  final void Function(int columnIndex, {required bool after})
  onTableColumnInserted;
  final ValueChanged<int> onTableColumnDeleted;
  final VoidCallback onTableDeleted;
  final VoidCallback onImageEditRequested;
  final VoidCallback onFocused;
  final bool selected;
  final BusyMarkWysiwygSelectionRange? selectionRange;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerMoveEvent>? onPointerMove;
  final ValueChanged<PointerUpEvent>? onPointerUp;

  @override
  Widget build(BuildContext context) {
    final style = _textStyle(context);
    final prefix = _prefix(context);
    final readOnly = _readOnly;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: Padding(
        padding: _padding,
        child: GestureDetector(
          key: block.kind == BusyBlockKind.image
              ? ValueKey('wysiwyg-image-block-${block.id}')
              : null,
          behavior: HitTestBehavior.translucent,
          onTap: block.kind == BusyBlockKind.table
              ? onFocused
              : block.kind == BusyBlockKind.image
              ? _editImageBlock
              : readOnly
              ? onFocused
              : _focusBlock,
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
                child: _blockContent(context, style, prefix, readOnly),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockContent(
    BuildContext context,
    TextStyle style,
    Widget? prefix,
    bool readOnly,
  ) {
    final colors = BusyMarkSurfaceColors.of(context);
    if (block.kind == BusyBlockKind.thematicBreak) {
      return _ThematicBreakBlockView(selected: selected);
    }
    if (block.kind == BusyBlockKind.table) {
      return _TableBlockEditor(
        block: block,
        onFocused: onFocused,
        onCellChanged: onTableCellChanged,
        onRowInserted: onTableRowInserted,
        onRowDeleted: onTableRowDeleted,
        onColumnInserted: onTableColumnInserted,
        onColumnDeleted: onTableColumnDeleted,
        onTableDeleted: onTableDeleted,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefix != null) ...[
          SizedBox(width: BusyMarkSizes.wysiwygPrefixWidth, child: prefix),
          const SizedBox(width: BusyMarkSpacing.sm),
        ],
        Expanded(
          child: block.kind == BusyBlockKind.image
              ? _ImageBlockEditor(
                  block: block,
                  documentFilePath: documentFilePath,
                  workspaceRoot: workspaceRoot,
                  writersideRoot: writersideRoot,
                  imagesDir: imagesDir,
                )
              : readOnly
              ? SelectableText(
                  _readOnlyText,
                  style: style.copyWith(
                    color: colors.mutedForeground,
                    fontFamily: BusyMarkTypography.monoFontFamily,
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _WysiwygSelectionPainter(
                            text: controller.text,
                            style: style,
                            selectionRange: selectionRange,
                            color: Theme.of(context).colorScheme.primary
                                .withValues(
                                  alpha: BusyMarkAlpha.previewHighlight,
                                ),
                            textDirection: Directionality.of(context),
                          ),
                        ),
                      ),
                    ),
                    TextSelectionTheme(
                      data: selectionRange == null
                          ? Theme.of(context).textSelectionTheme
                          : Theme.of(context).textSelectionTheme.copyWith(
                              selectionColor: BusyMarkLinuxPalette.transparent,
                            ),
                      child: TextField(
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
                          hoverColor: BusyMarkLinuxPalette.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: onFocused,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
        ),
      ],
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

  void _editImageBlock() {
    onFocused();
    onImageEditRequested();
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
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => fontSize * 2.4,
      BusyBlockKind.table => fontSize * 5.8,
      BusyBlockKind.thematicBreak => fontSize * 2.2,
      _ => fontSize * 1.7,
    };
  }

  bool get _readOnly {
    return block.preserveRaw || block.kind == BusyBlockKind.thematicBreak;
  }

  String get _readOnlyText {
    return block.rawSource ?? block.plainText;
  }

  EdgeInsets get _padding {
    return switch (block.kind) {
      BusyBlockKind.heading => BusyMarkInsets.wysiwygHeadingBlock,
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => BusyMarkInsets.wysiwygContainerBlock,
      BusyBlockKind.table => BusyMarkInsets.wysiwygTableBlock,
      BusyBlockKind.thematicBreak => BusyMarkInsets.wysiwygThematicBreakBlock,
      _ => BusyMarkInsets.wysiwygDefaultBlock,
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
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => BusyMarkInsets.wysiwygContainerContent,
      BusyBlockKind.table => BusyMarkInsets.wysiwygTableContent,
      BusyBlockKind.thematicBreak => BusyMarkInsets.wysiwygThematicBreakContent,
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
      BusyBlockKind.heading when level == 3 => theme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 4 => theme.titleSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 5 => theme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading => theme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.codeBlock => theme.bodyMedium!.copyWith(
        fontFamily: BusyMarkTypography.monoFontFamily,
        height: BusyMarkTypography.codeLineHeight,
      ),
      _ => theme.bodyMedium!.copyWith(
        height: BusyMarkTypography.bodyLineHeight,
      ),
    };
  }

  Widget? _prefix(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final markerStyle = _textStyle(context).copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem => Padding(
        padding: const EdgeInsets.only(top: BusyMarkSpacing.sm),
        child: SizedBox.square(
          dimension: BusyMarkSizes.markerDot,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.mutedForeground,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      BusyBlockKind.orderedListItem => Text(
        block.attributes['marker'] ?? '1.',
        textAlign: TextAlign.right,
        style: markerStyle,
      ),
      BusyBlockKind.taskListItem => Icon(
        block.attributes['task'] == 'true'
            ? BusyMarkGlyphs.checkedBox
            : BusyMarkGlyphs.task,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.blockquote => Icon(
        BusyMarkGlyphs.blockquote,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.codeBlock => Icon(
        BusyMarkGlyphs.code,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.writersideAdmonition => Icon(
        BusyMarkGlyphs.info,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
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
      _ => BusyMarkLinuxPalette.transparent,
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

class BusyMarkWysiwygSelectionRange {
  const BusyMarkWysiwygSelectionRange({required this.start, required this.end});

  final int start;
  final int end;
}

class _ThematicBreakBlockView extends StatelessWidget {
  const _ThematicBreakBlockView({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineColor = selected
        ? scheme.primary.withValues(alpha: BusyMarkAlpha.thematicBreakSelected)
        : colors.mutedForeground.withValues(alpha: BusyMarkAlpha.thematicBreak);
    final accentColor = selected
        ? scheme.primary
        : colors.mutedForeground.withValues(
            alpha: BusyMarkAlpha.thematicBreakHandle,
          );
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: BusyMarkStroke.thematicBreak,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
            ),
          ),
          Container(
            width: BusyMarkSizes.thematicBreakHandleWidth,
            height: BusyMarkSizes.markerDot,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableBlockEditor extends StatelessWidget {
  const _TableBlockEditor({
    required this.block,
    required this.onFocused,
    required this.onCellChanged,
    required this.onRowInserted,
    required this.onRowDeleted,
    required this.onColumnInserted,
    required this.onColumnDeleted,
    required this.onTableDeleted,
  });

  static const double _controlSize = BusyMarkSizes.tableControl;

  final BusyBlock block;
  final VoidCallback onFocused;
  final void Function(String cellId, String text) onCellChanged;
  final void Function(int rowIndex, {required bool after}) onRowInserted;
  final ValueChanged<int> onRowDeleted;
  final void Function(int columnIndex, {required bool after}) onColumnInserted;
  final ValueChanged<int> onColumnDeleted;
  final VoidCallback onTableDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final theme = Theme.of(context).textTheme;
    final rows = block.children;
    final columnCount = _columnCount(rows);
    final dataWidth = (columnCount * BusyMarkSizes.tableColumnBaseWidth)
        .clamp(BusyMarkSizes.tableMinWidth, BusyMarkSizes.tableMaxWidth)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: context.l10n.deleteTable,
            style: busyMarkHeaderIconButtonStyle(
              foregroundColor: colors.mutedForeground,
              backgroundColor: busyMarkHeaderButtonBackground(context),
            ),
            icon: const Icon(BusyMarkGlyphs.delete, size: BusyMarkSizes.iconSm),
            onPressed: onTableDeleted,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: dataWidth + _controlSize),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: colors.subtleBorder),
                verticalInside: BorderSide(color: colors.subtleBorder),
                top: BorderSide(color: colors.subtleBorder),
                right: BorderSide(color: colors.subtleBorder),
                bottom: BorderSide(color: colors.subtleBorder),
                left: BorderSide(color: colors.subtleBorder),
                borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(_controlSize),
                for (var index = 0; index < columnCount; index++)
                  index + 1: const FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.controlHover),
                  children: [
                    const _TableCornerCell(),
                    for (var column = 0; column < columnCount; column++)
                      _TableColumnControlCell(
                        columnIndex: column,
                        onInserted: onColumnInserted,
                        onDeleted: onColumnDeleted,
                      ),
                  ],
                ),
                for (final (rowIndex, row) in rows.indexed)
                  TableRow(
                    decoration: BoxDecoration(
                      color: _isHeaderRow(row, rowIndex)
                          ? colors.controlHover
                          : BusyMarkLinuxPalette.transparent,
                    ),
                    children: [
                      _TableRowControlCell(
                        rowIndex: rowIndex,
                        onInserted: onRowInserted,
                        onDeleted: onRowDeleted,
                      ),
                      for (var column = 0; column < columnCount; column++)
                        _TableCellEditor(
                          cell: column < row.children.length
                              ? row.children[column]
                              : null,
                          header: _isHeaderRow(row, rowIndex),
                          style: theme.bodyMedium!.copyWith(
                            height: BusyMarkTypography.codeLineHeight,
                          ),
                          onFocused: onFocused,
                          onChanged: onCellChanged,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _columnCount(List<BusyBlock> rows) {
    var count = 1;
    for (final row in rows) {
      if (row.children.length > count) {
        count = row.children.length;
      }
    }
    return count;
  }

  bool _isHeaderRow(BusyBlock row, int index) {
    return index == 0 || row.attributes['header'] == 'true';
  }
}

enum _TableControlAction { insertBefore, insertAfter, delete }

class _TableCornerCell extends StatelessWidget {
  const _TableCornerCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(dimension: _TableBlockEditor._controlSize);
  }
}

class _TableColumnControlCell extends StatelessWidget {
  const _TableColumnControlCell({
    required this.columnIndex,
    required this.onInserted,
    required this.onDeleted,
  });

  final int columnIndex;
  final void Function(int columnIndex, {required bool after}) onInserted;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    return _TableControlMenuButton(
      tooltip: context.l10n.tableColumnNumber(columnIndex + 1),
      icon: BusyMarkGlyphs.menuHorizontal,
      beforeLabel: context.l10n.insertColumnLeft,
      afterLabel: context.l10n.insertColumnRight,
      deleteLabel: context.l10n.deleteColumn,
      onSelected: (action) {
        switch (action) {
          case _TableControlAction.insertBefore:
            onInserted(columnIndex, after: false);
          case _TableControlAction.insertAfter:
            onInserted(columnIndex, after: true);
          case _TableControlAction.delete:
            onDeleted(columnIndex);
        }
      },
    );
  }
}

class _TableRowControlCell extends StatelessWidget {
  const _TableRowControlCell({
    required this.rowIndex,
    required this.onInserted,
    required this.onDeleted,
  });

  final int rowIndex;
  final void Function(int rowIndex, {required bool after}) onInserted;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    return _TableControlMenuButton(
      tooltip: context.l10n.tableRowNumber(rowIndex + 1),
      icon: BusyMarkGlyphs.menuVertical,
      beforeLabel: context.l10n.insertRowAbove,
      afterLabel: context.l10n.insertRowBelow,
      deleteLabel: context.l10n.deleteRow,
      onSelected: (action) {
        switch (action) {
          case _TableControlAction.insertBefore:
            onInserted(rowIndex, after: false);
          case _TableControlAction.insertAfter:
            onInserted(rowIndex, after: true);
          case _TableControlAction.delete:
            onDeleted(rowIndex);
        }
      },
    );
  }
}

class _TableControlMenuButton extends StatelessWidget {
  const _TableControlMenuButton({
    required this.tooltip,
    required this.icon,
    required this.beforeLabel,
    required this.afterLabel,
    required this.deleteLabel,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final String beforeLabel;
  final String afterLabel;
  final String deleteLabel;
  final ValueChanged<_TableControlAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<_TableControlAction>(
      tooltip: tooltip,
      icon: icon,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TableControlAction.insertBefore,
          child: Text(beforeLabel),
        ),
        PopupMenuItem(
          value: _TableControlAction.insertAfter,
          child: Text(afterLabel),
        ),
        PopupMenuItem(
          value: _TableControlAction.delete,
          child: Text(deleteLabel),
        ),
      ],
      onSelected: onSelected,
    );
  }
}

class _TableCellEditor extends StatefulWidget {
  const _TableCellEditor({
    required this.cell,
    required this.header,
    required this.style,
    required this.onFocused,
    required this.onChanged,
  });

  final BusyBlock? cell;
  final bool header;
  final TextStyle style;
  final VoidCallback onFocused;
  final void Function(String cellId, String text) onChanged;

  @override
  State<_TableCellEditor> createState() => _TableCellEditorState();
}

class _TableCellEditorState extends State<_TableCellEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _cellId;

  @override
  void initState() {
    super.initState();
    _cellId = widget.cell?.id;
    _controller = TextEditingController(text: widget.cell?.plainText ?? '');
    _focusNode = FocusNode(debugLabel: 'BusyMark table cell $_cellId');
  }

  @override
  void didUpdateWidget(covariant _TableCellEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cell = widget.cell;
    if (cell?.id != _cellId) {
      _cellId = cell?.id;
      _controller.text = cell?.plainText ?? '';
      return;
    }
    if (!_focusNode.hasFocus &&
        cell != null &&
        cell.plainText != _controller.text) {
      _controller.text = cell.plainText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final cell = widget.cell;
    final textStyle = widget.style.copyWith(
      fontWeight: widget.header ? FontWeight.w700 : FontWeight.w400,
    );
    if (cell == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: BusyMarkInsets.wysiwygTableCell,
      child: TextField(
        key: ValueKey(cell.id),
        controller: _controller,
        focusNode: _focusNode,
        minLines: 1,
        maxLines: null,
        style: textStyle,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hoverColor: BusyMarkLinuxPalette.transparent,
          hintText: widget.header
              ? context.l10n.tableHeaderHint
              : context.l10n.tableCellHint,
          hintStyle: textStyle.copyWith(color: colors.mutedForeground),
          contentPadding: EdgeInsets.zero,
        ),
        onTap: widget.onFocused,
        onChanged: (value) => widget.onChanged(cell.id, value),
      ),
    );
  }
}

class _WysiwygSelectionPainter extends CustomPainter {
  const _WysiwygSelectionPainter({
    required this.text,
    required this.style,
    required this.selectionRange,
    required this.color,
    required this.textDirection,
  });

  final String text;
  final TextStyle style;
  final BusyMarkWysiwygSelectionRange? selectionRange;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final range = selectionRange;
    if (range == null || text.isEmpty || size.width <= 0) {
      return;
    }
    final start = range.start.clamp(0, text.length).toInt();
    final end = range.end.clamp(0, text.length).toInt();
    if (end <= start) {
      return;
    }
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
    )..layout(maxWidth: size.width);
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
    final paint = Paint()..color = color;
    for (final box in boxes) {
      final rect = Rect.fromLTRB(
        box.left,
        box.top,
        box.right,
        box.bottom,
      ).inflate(BusyMarkStroke.selectionInflate);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(BusyMarkRadius.selection),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WysiwygSelectionPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.selectionRange?.start != selectionRange?.start ||
        oldDelegate.selectionRange?.end != selectionRange?.end ||
        oldDelegate.color != color ||
        oldDelegate.textDirection != textDirection;
  }
}

class _ImageBlockEditor extends StatelessWidget {
  const _ImageBlockEditor({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;

  @override
  Widget build(BuildContext context) {
    final source = _imageSource(block);
    return Align(
      alignment: Alignment.centerLeft,
      child: MarkdownImageView(
        source: source,
        alt: block.plainText,
        activeFilePath: documentFilePath,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
      ),
    );
  }
}

String _imageSource(BusyBlock block) {
  final attributeSource = block.attributes['src'];
  if (attributeSource != null && attributeSource.trim().isNotEmpty) {
    return attributeSource.trim();
  }
  for (final inline in block.inlines) {
    if (inline.kind == BusyInlineKind.image &&
        inline.destination != null &&
        inline.destination!.trim().isNotEmpty) {
      return inline.destination!.trim();
    }
  }
  return '';
}
