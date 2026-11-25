class TableGridCell<T> {
  const TableGridCell(
    this.value,
    this.row,
    this.column,
    this.rowspan,
    this.colspan,
  );
  final T value;
  final int row;
  final int column;
  final int rowspan;
  final int colspan;
}

class TableGrid<T> {
  const TableGrid(this.cells, this.rows, this.columns);
  final List<TableGridCell<T>> cells;
  final int rows;
  final int columns;

  factory TableGrid.place(
    List<List<T>> rows,
    Map<String, String> Function(T) attributes,
  ) {
    // A span occupies a column until its last row. Keep one entry per column
    // rather than allocating a Cartesian product of span coordinates.
    final occupiedUntil = <int, int>{};
    final cells = <TableGridCell<T>>[];
    var columns = 0;
    for (var row = 0; row < rows.length; row++) {
      var column = 0;
      for (final value in rows[row]) {
        final attrs = attributes(value);
        final colspan = (int.tryParse(attrs['colspan'] ?? '') ?? 1).clamp(
          1,
          100,
        );
        final rowspan = (int.tryParse(attrs['rowspan'] ?? '') ?? 1).clamp(
          1,
          rows.length - row,
        );
        while (List.generate(
          colspan,
          (index) => occupiedUntil[column + index] ?? 0,
        ).any((end) => row < end)) {
          column++;
        }
        cells.add(TableGridCell(value, row, column, rowspan, colspan));
        for (var x = column; x < column + colspan; x++) {
          occupiedUntil[x] = row + rowspan;
        }
        column += colspan;
        if (column > columns) columns = column;
      }
    }
    return TableGrid(cells, rows.length, columns);
  }
}

int naturalTableCompare(String first, String second) {
  final parts = RegExp(r'\d+|\D+');
  final a = parts
      .allMatches(first.toLowerCase())
      .map((match) => match[0]!)
      .toList();
  final b = parts
      .allMatches(second.toLowerCase())
      .map((match) => match[0]!)
      .toList();
  for (var i = 0; i < a.length && i < b.length; i++) {
    final numberA = BigInt.tryParse(a[i]);
    final numberB = BigInt.tryParse(b[i]);
    final compared = numberA != null && numberB != null
        ? numberA.compareTo(numberB)
        : a[i].compareTo(b[i]);
    if (compared != 0) return compared;
  }
  return a.length.compareTo(b.length);
}
