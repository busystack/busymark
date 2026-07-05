import '../../core/diagnostic.dart';
import 'source_document.dart';

class SourceDiagnosticMarker {
  const SourceDiagnosticMarker({
    required this.diagnostic,
    required this.fullLine,
    required this.visibleLine,
    required this.hidden,
  });

  final Diagnostic diagnostic;
  final int fullLine;
  final int? visibleLine;
  final bool hidden;
}

List<SourceDiagnosticMarker> sourceDiagnosticMarkers({
  required SourceDocument document,
  required Iterable<Diagnostic> diagnostics,
  required String filePath,
}) {
  final markers = <SourceDiagnosticMarker>[];
  for (final diagnostic in diagnostics) {
    if (diagnostic.filePath != filePath) {
      continue;
    }
    final span = diagnostic.sourceSpan;
    final fullLine =
        span?.startLine ??
        document.lineIndex.lineNumberAtOffset(span?.startOffset ?? 0);
    final hidden = span == null
        ? false
        : document.hiddenRanges
              .hiddenRangesIntersecting(span.startOffset, span.endOffset)
              .isNotEmpty;
    markers.add(
      SourceDiagnosticMarker(
        diagnostic: diagnostic,
        fullLine: fullLine,
        visibleLine: document.visibleLineForFullLine(fullLine)?.number,
        hidden: hidden,
      ),
    );
  }
  markers.sort((a, b) {
    final line = a.fullLine.compareTo(b.fullLine);
    if (line != 0) {
      return line;
    }
    return b.diagnostic.severity.rank.compareTo(a.diagnostic.severity.rank);
  });
  return markers;
}
