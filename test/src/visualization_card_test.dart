import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/visualization/visualization_cache.dart';
import 'package:busymark/src/visualization/visualization_card.dart';
import 'package:busymark/src/visualization/visualization_coordinator.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/visualization/visualization_providers.dart';
import 'package:busymark/src/visualization/visualization_renderer.dart';
import 'package:busymark/src/visualization/web_render_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory cacheDirectory;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('busymark-card-');
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  testWidgets('retains the last valid diagram and navigates new diagnostics', (
    tester,
  ) async {
    final coordinator = VisualizationCoordinator(
      renderers: const [_CardRenderer()],
      cache: _MemoryVisualizationCache(cacheDirectory),
    );
    addTearDown(coordinator.dispose);
    final host = _OpenReferenceHost();
    final key = GlobalKey<_CardHarnessState>();
    int? selectedLine;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visualizationCoordinatorProvider.overrideWithValue(coordinator),
          webRenderHostProvider.overrideWithValue(host),
        ],
        child: _App(
          child: _CardHarness(
            key: key,
            onDiagnosticSelected: (line) => selectedLine = line,
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.byType(SvgPicture));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Broken diagram'), findsNothing);
    await tester.tap(find.byTooltip('Copy image'));
    await tester.pump();
    expect(host.rasterCalls, 1);
    expect(host.copiedPng, isNotEmpty);

    key.currentState!.updateSource('broken source');
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpUntilFound(tester, find.text('Broken diagram'));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Broken diagram'), findsOneWidget);
    expect(find.text('Showing the last valid render'), findsOneWidget);
    await tester.ensureVisible(find.text('Broken diagram'));
    await tester.pump();
    await tester.tap(find.text('Broken diagram'));
    await tester.pump();
    expect(selectedLine, 12);
    expect(find.textContaining('```MerMAID'), findsOneWidget);
  });

  testWidgets(
    'shows searchable OpenAPI operations and opens the native reference',
    (tester) async {
      final coordinator = VisualizationCoordinator(
        renderers: const [_CardRenderer()],
        cache: _MemoryVisualizationCache(cacheDirectory),
      );
      addTearDown(coordinator.dispose);
      final host = _OpenReferenceHost();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            visualizationCoordinatorProvider.overrideWithValue(coordinator),
            webRenderHostProvider.overrideWithValue(host),
          ],
          child: const _App(child: _OpenApiCard()),
        ),
      );
      await _pumpUntilFound(tester, find.text('Demo API'));

      expect(find.text('Demo API'), findsOneWidget);
      expect(
        find.text('openapi/components.yaml:14:7: Dependency warning'),
        findsOneWidget,
      );
      expect(find.text('/notes'), findsOneWidget);
      expect(find.text('/users'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'users');
      await tester.pump();
      expect(find.text('/notes'), findsNothing);
      expect(find.text('/users'), findsOneWidget);
      await tester.tap(find.text('Open API Reference'));
      await tester.pump();
      expect(host.openCalls, 1);
      expect(host.lastTitle, 'Demo API');
    },
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

class _MemoryVisualizationCache extends VisualizationCache {
  _MemoryVisualizationCache(Directory directory) : super(diskRoot: directory);

  final Map<String, VisualizationRenderResult> _entries = {};

  @override
  Future<VisualizationRenderResult?> get(String key) async => _entries[key];

  @override
  Future<void> put(String key, VisualizationRenderResult result) async {
    if (result.isSuccessful) {
      _entries[key] = result;
    }
  }
}

class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }
}

class _CardHarness extends StatefulWidget {
  const _CardHarness({super.key, required this.onDiagnosticSelected});

  final ValueChanged<int> onDiagnosticSelected;

  @override
  State<_CardHarness> createState() => _CardHarnessState();
}

class _CardHarnessState extends State<_CardHarness> {
  var source = 'graph TD; A-->B';
  var revision = 1;

  void updateSource(String value) {
    setState(() {
      source = value;
      revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BusyMarkVisualizationCard(
      descriptor: VisualizationDescriptor.forFenceLanguage('MerMAID'),
      source: source,
      sourceFence: '```MerMAID\n$source\n```',
      documentPath: '/workspace/demo.md',
      workspaceRoot: '/workspace',
      sourceStartLine: 10,
      editRevision: revision,
      blockKey: 'preview:block',
      onDiagnosticSelected: widget.onDiagnosticSelected,
    );
  }
}

class _OpenApiCard extends StatelessWidget {
  const _OpenApiCard();

  @override
  Widget build(BuildContext context) {
    return BusyMarkVisualizationCard(
      descriptor: VisualizationDescriptor.forFenceLanguage('openapi'),
      source: 'openapi: 3.1.0',
      sourceFence: '```openapi\nopenapi: 3.1.0\n```',
      documentPath: '/workspace/demo.md',
      workspaceRoot: '/workspace',
      sourceStartLine: 1,
      editRevision: 1,
      blockKey: 'preview:openapi',
    );
  }
}

class _CardRenderer implements VisualizationRenderer {
  const _CardRenderer();

  @override
  Set<VisualizationRendererKind> get supportedKinds => const {
    VisualizationRendererKind.mermaid,
    VisualizationRendererKind.openApi,
  };

  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    return request;
  }

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    if (request.kind == VisualizationRendererKind.openApi) {
      return const OpenApiVisualizationResult(
        content: 'openapi: 3.1.0',
        diagnostics: [
          VisualizationDiagnostic(
            code: 'visualization.openapiWarning',
            message: 'Dependency warning',
            severity: VisualizationDiagnosticSeverity.warning,
            sourceId: 'openapi/components.yaml',
            sourceLine: 14,
            sourceColumn: 7,
          ),
        ],
        reference: OpenApiReferenceModel(
          title: 'Demo API',
          apiVersion: '1.0.0',
          specificationVersion: '3.1.0',
          valid: true,
          serverCount: 1,
          pathCount: 2,
          tags: ['Notes', 'Users'],
          operations: [
            OpenApiOperation(
              method: 'GET',
              path: '/notes',
              summary: 'List notes',
              operationId: 'listNotes',
              tags: ['Notes'],
            ),
            OpenApiOperation(
              method: 'GET',
              path: '/users',
              summary: 'List users',
              operationId: 'listUsers',
              tags: ['Users'],
            ),
          ],
          document: {'openapi': '3.1.0'},
        ),
      );
    }
    if (request.source.contains('broken')) {
      return const FailedVisualizationResult(
        code: 'visualization.invalidMermaid',
        message: 'Broken diagram',
        retryable: false,
        diagnostics: [
          VisualizationDiagnostic(
            code: 'visualization.invalidMermaid',
            message: 'Broken diagram',
            severity: VisualizationDiagnosticSeverity.error,
            line: 2,
            column: 1,
          ),
        ],
      );
    }
    return const SvgVisualizationResult(
      svg:
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10"/></svg>',
      width: 10,
      height: 10,
    );
  }
}

class _OpenReferenceHost implements WebRenderHost {
  var openCalls = 0;
  var rasterCalls = 0;
  String? lastTitle;
  Uint8List copiedPng = Uint8List(0);

  @override
  Future<void> copyPngToClipboard(Uint8List pngBytes) async {
    copiedPng = pngBytes;
  }

  @override
  Future<void> openOpenApiReference({
    required String title,
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationTheme theme,
  }) async {
    openCalls++;
    lastTitle = title;
  }

  @override
  Future<List<OpenApiSourceReference>> inspectOpenApiReferences(
    String source,
    VisualizationCancellationToken cancellationToken,
  ) => throw UnimplementedError();

  @override
  Future<Map<Object?, Object?>> parseOpenApi({
    required String entryId,
    required String source,
    required List<VisualizationDependency> dependencies,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> rasterizeSvg({
    required String svg,
    required double width,
    required double height,
    required double scale,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    rasterCalls++;
    return Uint8List.fromList([137, 80, 78, 71]);
  }

  @override
  Future<Map<Object?, Object?>> renderMermaid({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<Map<Object?, Object?>> renderPlantUml({
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) => throw UnimplementedError();
}
