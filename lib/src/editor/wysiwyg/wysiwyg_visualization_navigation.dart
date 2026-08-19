int wysiwygVisualizationDiagnosticOffset({
  required String text,
  required int blockStartLine,
  required int documentLine,
}) {
  final requestedLine = documentLine - blockStartLine - 1;
  final targetLine = requestedLine < 0 ? 0 : requestedLine;
  var offset = 0;
  var currentLine = 0;
  while (currentLine < targetLine && offset < text.length) {
    final newline = text.indexOf('\n', offset);
    if (newline < 0) {
      return text.length;
    }
    offset = newline + 1;
    currentLine++;
  }
  return offset;
}
