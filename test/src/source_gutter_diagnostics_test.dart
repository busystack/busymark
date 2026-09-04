import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_diagnostics.dart';
import 'package:busymark/src/editor/source/source_document.dart';
import 'package:busymark/src/editor/source/source_gutter.dart';
import 'package:busymark/src/editor/source/source_hidden_ranges.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/editor/source_folding.dart';
import 'package:flutter/material.dart';
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
    'diagnostic inside folded region is aggregated onto its fold header',
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
      expect(gutter.first.diagnostics, [markers.single]);
      expect(
        gutter.first.diagnostics.single.diagnostic.severity,
        DiagnosticSeverity.warning,
      );
    },
  );

  testWidgets('folded layout geometry is reused for equal collapsed sets', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    const source = '# Heading\nBody\nMore\n# Next\n';
    final folds = sourceFoldRegions(source, SourceSyntaxLanguage.markdown);
    final fold = folds.firstWhere((region) => region.startLine == 1);
    final controller = BusyMarkSourceEditingController(text: source)
      ..setFoldedRegions([fold]);
    addTearDown(controller.dispose);
    final cache = SourceLineLayoutCache();

    List<SourceLineLayoutEntry> resolve(Set<String> keys) => cache.resolve(
      context,
      controller: controller,
      foldRegions: folds,
      collapsedRegionKeys: keys,
      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      strutStyle: const StrutStyle(fontFamily: 'monospace', fontSize: 14),
      lineHeight: 18,
      textWidth: 400,
      diagnostics: const [],
    );

    final first = resolve({fold.key});
    final second = resolve({fold.key});

    expect(identical(first, second), isTrue);
  });

  testWidgets('incremental gutter layout matches a full measured layout', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    const style = TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.3);
    const strut = StrutStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.3,
    );
    const lineHeight = 18.2;
    const textWidth = 90.0;
    final controller = BusyMarkSourceEditingController(
      text: '# Heading\nA wrapped plain line with several words.\nTail\n',
      language: SourceSyntaxLanguage.markdown,
    );
    addTearDown(controller.dispose);
    final cache = SourceLineLayoutCache();

    List<SourceLineLayoutEntry> resolve() => cache.resolve(
      context,
      controller: controller,
      foldRegions: sourceFoldRegions(
        controller.fullText,
        SourceSyntaxLanguage.markdown,
      ),
      collapsedRegionKeys: const {},
      textStyle: style,
      strutStyle: strut,
      lineHeight: lineHeight,
      textWidth: textWidth,
      diagnostics: const [],
    );

    void expectMatchesFullLayout() {
      final incremental = resolve();
      final full = sourceLineLayoutEntries(
        context,
        controller: controller,
        foldRegions: sourceFoldRegions(
          controller.fullText,
          SourceSyntaxLanguage.markdown,
        ),
        collapsedRegionKeys: const {},
        textStyle: style,
        strutStyle: strut,
        lineHeight: lineHeight,
        textWidth: textWidth,
      );
      expect(incremental, hasLength(full.length));
      for (var index = 0; index < full.length; index++) {
        expect(
          incremental[index].top,
          closeTo(full[index].top, 0.01),
          reason: 'top for line ${index + 1}',
        );
        expect(
          incremental[index].height,
          closeTo(full[index].height, 0.01),
          reason: 'height for line ${index + 1}',
        );
        expect(
          incremental[index].gutterLine.fullLine,
          full[index].gutterLine.fullLine,
        );
      }
    }

    resolve();
    controller.value = TextEditingValue(
      text: controller.fullText.replaceFirst('words.', 'words!'),
      selection: const TextSelection.collapsed(offset: 51),
    );
    expectMatchesFullLayout();

    controller.value = TextEditingValue(
      text: controller.fullText.replaceFirst('plain line', 'plain\nline'),
      selection: const TextSelection.collapsed(offset: 28),
    );
    expectMatchesFullLayout();

    controller.value = TextEditingValue(
      text: controller.fullText.replaceFirst('plain\nline', 'plain line'),
      selection: const TextSelection.collapsed(offset: 28),
    );
    expectMatchesFullLayout();

    controller.value = TextEditingValue(
      text: controller.fullText.replaceFirst('plain line', '**plain line**'),
      selection: const TextSelection.collapsed(offset: 30),
    );
    expectMatchesFullLayout();

    controller.value = TextEditingValue(
      text: controller.fullText.replaceFirst('# Heading', '## Heading'),
      selection: const TextSelection.collapsed(offset: 2),
    );
    expectMatchesFullLayout();
  });
}
