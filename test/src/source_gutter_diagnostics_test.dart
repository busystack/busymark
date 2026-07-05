import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_diagnostics.dart';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_gutter.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diagnostic maps to full and visible line without folds', () {
    const source = '# Title\nBroken link\n';
    final diagnostic = Diagnostic(
      code: 'markdown.link.unresolved',
      severity: DiagnosticSeverity.error,
      filePath: 'doc.md',
      sourceSpan: SourceSpan.fromOffsets(
        filePath: 'doc.md',
        source: source,
        startOffset: source.indexOf('Broken'),
        endOffset: source.indexOf('Broken') + 6,
      ),
    );

    final markers = sourceDiagnosticMarkers(
      document: SourceDocument(fullText: source),
      diagnostics: [diagnostic],
      filePath: 'doc.md',
    );

    expect(markers.single.fullLine, 2);
    expect(markers.single.visibleLine, 2);
    expect(markers.single.hidden, isFalse);
  });

  test(
    'diagnostic inside folded region is safe and gutter skips hidden line',
    () {
      const source = '# Title\nBroken link\n# Next\n';
      final fold = sourceFoldRegions(
        source,
        SourceSyntaxLanguage.markdown,
      ).firstWhere((region) => region.startLine == 1);
      final document = SourceDocument(
        fullText: source,
        hiddenRanges: SourceHiddenRanges(
          ranges: [
            SourceHiddenRange(
              start: fold.hiddenStartOffset,
              end: fold.hiddenEndOffset,
              key: fold.key,
            ),
          ],
          textLength: source.length,
        ),
      );
      final diagnostic = Diagnostic(
        code: 'markdown.link.unresolved',
        severity: DiagnosticSeverity.warning,
        filePath: 'doc.md',
        sourceSpan: SourceSpan.fromOffsets(
          filePath: 'doc.md',
          source: source,
          startOffset: source.indexOf('Broken'),
          endOffset: source.indexOf('Broken') + 6,
        ),
      );
      final markers = sourceDiagnosticMarkers(
        document: document,
        diagnostics: [diagnostic],
        filePath: 'doc.md',
      );
      final gutter = sourceGutterModel(
        document: document,
        foldRegions: [fold],
        collapsedRegionKeys: {fold.key},
        diagnostics: markers,
      );

      expect(markers.single.fullLine, 2);
      expect(markers.single.visibleLine, isNull);
      expect(markers.single.hidden, isTrue);
      expect(gutter.map((line) => line.fullLine), [1, 3, 4]);
      expect(gutter.first.foldable, isTrue);
      expect(gutter.first.collapsed, isTrue);
    },
  );
}
