import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_visualization_navigation.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory cacheDirectory;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp(
      'busymark-wysiwyg-visualization-',
    );
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  test('computes the diagnostic offset within fenced source', () {
    const source = 'first\nsecond\nthird';

    expect(
      wysiwygVisualizationDiagnosticOffset(
        text: source,
        blockStartLine: 5,
        documentLine: 8,
      ),
      13,
    );
    expect(
      wysiwygVisualizationDiagnosticOffset(
        text: source,
        blockStartLine: 5,
        documentLine: 6,
      ),
      0,
    );
    expect(
      wysiwygVisualizationDiagnosticOffset(
        text: source,
        blockStartLine: 5,
        documentLine: 99,
      ),
      source.length,
    );
  });

  testWidgets(
    'WYSIWYG diagnostic selects its actual source line',
    (tester) async {
      final coordinator = VisualizationCoordinator(
        renderers: const [_DiagnosticRenderer()],
        cache: _MemoryVisualizationCache(cacheDirectory),
      );
      addTearDown(coordinator.dispose);
      final controller = BusyMarkWysiwygTextController(
        text: 'first\nsecond\nthird',
        ranges: const [],
      );
      final undoController = UndoHistoryController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(undoController.dispose);
      addTearDown(focusNode.dispose);
      var focusCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visualizationCoordinatorProvider.overrideWithValue(coordinator),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusyMarkWysiwygBlockField(
                  block: const BusyBlock(
                    id: 'diagram',
                    kind: BusyBlockKind.codeBlock,
                    attributes: {'language': 'mermaid'},
                    inlines: [
                      BusyInline(
                        kind: BusyInlineKind.text,
                        text: 'first\nsecond\nthird',
                      ),
                    ],
                    sourceSpan: SourceSpan(
                      filePath: '/workspace/demo.md',
                      startOffset: 20,
                      endOffset: 55,
                      startLine: 5,
                      startColumn: 1,
                      endLine: 9,
                      endColumn: 4,
                    ),
                  ),
                  documentFilePath: '/workspace/demo.md',
                  workspaceRoot: '/workspace',
                  allowRemoteImages: false,
                  controller: controller,
                  undoController: undoController,
                  focusNode: focusNode,
                  onChanged: (_) {},
                  onTableCellChanged: (_, _) {},
                  onTableRowInserted: (_, {required after}) {},
                  onTableRowDeleted: (_) {},
                  onTableColumnInserted: (_, {required after}) {},
                  onTableColumnDeleted: (_) {},
                  onTableDeleted: () {},
                  onImageEditRequested: () {},
                  onHtmlEditRequested: () {},
                  onTaskChanged: (_) {},
                  onFocused: () => focusCalls++,
                ),
              ),
            ),
          ),
        ),
      );

      await _pumpUntilFound(tester, find.text('Broken third line'));
      await tester.tap(find.text('Broken third line'));
      await tester.pump();

      expect(focusCalls, 1);
      expect(focusNode.hasFocus, isTrue);
      expect(controller.selection, const TextSelection.collapsed(offset: 13));
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder.');
}

class _DiagnosticRenderer implements VisualizationRenderer {
  const _DiagnosticRenderer();

  @override
  Set<VisualizationRendererKind> get supportedKinds => const {
    VisualizationRendererKind.mermaid,
  };

  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async => request;

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    return const FailedVisualizationResult(
      code: 'visualization.invalidSource',
      message: 'Broken diagram',
      diagnostics: [
        VisualizationDiagnostic(
          code: 'visualization.invalidSource',
          message: 'Broken third line',
          severity: VisualizationDiagnosticSeverity.error,
          line: 3,
          column: 1,
        ),
      ],
    );
  }
}

class _MemoryVisualizationCache extends VisualizationCache {
  _MemoryVisualizationCache(Directory directory) : super(diskRoot: directory);

  @override
  Future<VisualizationRenderResult?> get(String key) async => null;

  @override
  Future<void> put(String key, VisualizationRenderResult result) async {}
}
