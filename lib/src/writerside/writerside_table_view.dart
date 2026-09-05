import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../markdown/preview_model.dart';
import '../app/localization.dart';
import '../app/busymark_glyphs.dart';
import '../markdown/table_grid.dart';

class WritersideTableView extends StatefulWidget {
  const WritersideTableView({
    super.key,
    required this.block,
    required this.cellBuilder,
  });
  final PreviewBlock block;
  final Widget Function(PreviewBlock, bool) cellBuilder;
  @override
  State<WritersideTableView> createState() => _WritersideTableViewState();
}

class _WritersideTableViewState extends State<WritersideTableView> {
  int? sortColumn;
  bool ascending = true;
  @override
  Widget build(BuildContext context) {
    final rows = widget.block.children;
    if (rows.isEmpty) return const SizedBox.shrink();
    var grid = TableGrid.place(
      rows.map((row) => row.children).toList(),
      (cell) => cell.attributes,
    );
    if (sortColumn != null) {
      // A rowspan ties rows together. Move whole groups to preserve cell identity.
      final groups = <List<int>>[];
      var row = 1;
      while (row < rows.length) {
        var end = row + 1;
        for (var current = row; current < end; current++) {
          for (final cell in grid.cells.where((cell) => cell.row == current)) {
            end = math.max(end, cell.row + cell.rowspan);
          }
        }
        groups.add(List.generate(end - row, (index) => row + index));
        row = end;
      }
      String text(int row) {
        final cell = grid.cells
            .where((cell) => cell.row == row && cell.column == sortColumn)
            .firstOrNull
            ?.value;
        String flatten(PreviewBlock block) =>
            '${block.text} ${block.children.map(flatten).join(' ')}';
        return cell == null ? '' : flatten(cell);
      }

      groups.sort((a, b) {
        final result = naturalTableCompare(text(a.first), text(b.first));
        return result == 0
            ? a.first.compareTo(b.first)
            : ascending
            ? result
            : -result;
      });
      grid = TableGrid.place([
        rows.first.children,
        for (final group in groups)
          for (final index in group) rows[index].children,
      ], (cell) => cell.attributes);
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: _TableLayout(
        grid: grid,
        fixed: widget.block.attributes['column-width'] == 'fixed',
        sticky:
            widget.block.attributes['sticky-header'] == 'true' &&
            rows.first.attributes['header'] == 'true',
        scrollPosition: Scrollable.maybeOf(context)?.position,
        children: [
          for (final cell in grid.cells)
            (() {
              final header =
                  cell.value.attributes['header'] == 'true' ||
                  (cell.row == 0 && rows.first.attributes['header'] == 'true');
              final sortable =
                  widget.block.attributes['sortable'] == 'true' &&
                  cell.row == 0 &&
                  header &&
                  cell.value.attributes['sortable'] != 'false' &&
                  cell.colspan == 1 &&
                  cell.rowspan == 1;
              final content = widget.cellBuilder(cell.value, header);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: header
                      ? scheme.surfaceContainerHighest
                      : scheme.surface,
                  border: Border.all(color: scheme.outlineVariant, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: sortable
                      ? InkWell(
                          onTap: () => setState(() {
                            ascending = sortColumn == cell.column
                                ? !ascending
                                : true;
                            sortColumn = cell.column;
                          }),
                          child: Semantics(
                            button: true,
                            label: context.l10n.sortTableColumn(
                              cell.value.text,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: content),
                                Icon(
                                  sortColumn == cell.column && !ascending
                                      ? BusyMarkGlyphs.downArrow
                                      : BusyMarkGlyphs.upArrow,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        )
                      : content,
                ),
              );
            })(),
        ],
      ),
    );
  }
}

class _TableLayout extends MultiChildRenderObjectWidget {
  const _TableLayout({
    required this.grid,
    required this.fixed,
    required this.sticky,
    required this.scrollPosition,
    required super.children,
  });
  final TableGrid<PreviewBlock> grid;
  final bool fixed;
  final bool sticky;
  final ScrollPosition? scrollPosition;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTable(grid, fixed, sticky, scrollPosition);
  @override
  void updateRenderObject(BuildContext context, _RenderTable renderObject) {
    renderObject.update(grid, fixed, sticky, scrollPosition);
  }
}

class _CellParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellParentData> {
  _RenderTable(this.grid, this.fixed, this.sticky, this.position);
  TableGrid<PreviewBlock> grid;
  bool fixed;
  bool sticky;
  ScrollPosition? position;
  List<double> rowHeights = [];
  void update(
    TableGrid<PreviewBlock> value,
    bool fixedWidth,
    bool stickyHeader,
    ScrollPosition? scroll,
  ) {
    if (attached) position?.removeListener(_scrolled);
    grid = value;
    fixed = fixedWidth;
    sticky = stickyHeader;
    position = scroll;
    if (attached) position?.addListener(_scrolled);
    markNeedsLayout();
  }

  void _scrolled() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    position?.addListener(_scrolled);
  }

  @override
  void detach() {
    position?.removeListener(_scrolled);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellParentData) {
      child.parentData = _CellParentData();
    }
  }

  @override
  void performLayout() {
    if (grid.columns == 0) {
      size = constraints.smallest;
      return;
    }
    final children = getChildrenAsList();
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 800.0;
    final widths = List<double>.filled(grid.columns, 1);
    final explicit = <int, double>{};
    for (var i = 0; i < grid.cells.length; i++) {
      final cell = grid.cells[i];
      if (cell.colspan != 1) continue;
      final specified = double.tryParse(cell.value.attributes['width'] ?? '');
      if (specified != null && specified > 0) explicit[cell.column] = specified;
      if (!fixed) {
        widths[cell.column] = math.max(
          widths[cell.column],
          (cell.value.text.length * 7.0 + 20).clamp(40, 400),
        );
      }
    }
    final reserved = explicit.values.fold(0.0, (sum, value) => sum + value);
    final available = math.max(width * 0.2, width - reserved);
    final weight = [
      for (var i = 0; i < widths.length; i++)
        if (!explicit.containsKey(i)) widths[i],
    ].fold(0.0, (a, b) => a + b);
    for (var i = 0; i < widths.length; i++) {
      widths[i] = explicit[i] ?? available * widths[i] / math.max(1, weight);
    }
    final total = widths.fold(0.0, (a, b) => a + b);
    if (total > width) {
      for (var i = 0; i < widths.length; i++) {
        widths[i] *= width / total;
      }
    }
    double sum(List<double> values, int start, int count) =>
        values.skip(start).take(count).fold(0, (a, b) => a + b);
    rowHeights = List.filled(grid.rows, 0);
    for (var i = 0; i < children.length; i++) {
      final cell = grid.cells[i];
      children[i].layout(
        BoxConstraints.tightFor(width: sum(widths, cell.column, cell.colspan)),
        parentUsesSize: true,
      );
      if (cell.rowspan == 1) {
        rowHeights[cell.row] = math.max(
          rowHeights[cell.row],
          children[i].size.height,
        );
      }
    }
    for (var i = 0; i < children.length; i++) {
      final cell = grid.cells[i];
      final missing =
          children[i].size.height - sum(rowHeights, cell.row, cell.rowspan);
      if (missing > 0) {
        for (var r = cell.row; r < cell.row + cell.rowspan; r++) {
          rowHeights[r] += missing / cell.rowspan;
        }
      }
    }
    for (var i = 0; i < children.length; i++) {
      final cell = grid.cells[i];
      children[i].layout(
        BoxConstraints.tight(
          Size(
            sum(widths, cell.column, cell.colspan),
            sum(rowHeights, cell.row, cell.rowspan),
          ),
        ),
      );
      (children[i].parentData! as _CellParentData).offset = Offset(
        sum(widths, 0, cell.column),
        sum(rowHeights, 0, cell.row),
      );
    }
    size = constraints.constrain(
      Size(width, sum(rowHeights, 0, rowHeights.length)),
    );
  }

  double get stickyOffset {
    if (!sticky || rowHeights.isEmpty) return 0;
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport is! RenderBox) return 0;
    final y = localToGlobal(Offset.zero, ancestor: viewport).dy;
    return (-y).clamp(0, math.max(0, size.height - rowHeights.first));
  }

  Offset offsetFor(RenderBox child, int index) =>
      (child.parentData! as _CellParentData).offset +
      Offset(0, grid.cells[index].row == 0 ? stickyOffset : 0);
  @override
  void paint(PaintingContext context, Offset offset) {
    final children = getChildrenAsList();
    for (final header in [false, true]) {
      for (var i = 0; i < children.length; i++) {
        if ((grid.cells[i].row == 0) == header) {
          context.paintChild(children[i], offset + offsetFor(children[i], i));
        }
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final children = getChildrenAsList();
    final order = [
      for (var i = 0; i < children.length; i++)
        if (grid.cells[i].row == 0) i,
      for (var i = children.length - 1; i >= 0; i--)
        if (grid.cells[i].row != 0) i,
    ];
    for (final i in order) {
      if (result.addWithPaintOffset(
        offset: offsetFor(children[i], i),
        position: position,
        hitTest: (result, transformed) =>
            children[i].hitTest(result, position: transformed),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = offsetFor(child, getChildrenAsList().indexOf(child));
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }
}
