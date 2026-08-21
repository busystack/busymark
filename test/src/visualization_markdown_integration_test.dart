import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/source_highlighter.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'visualizer fences remain generic code and round-trip byte-for-byte',
    () {
      const source = '''
# Demo

````MerMAID custom=preserved
flowchart LR
  A --> B
````

```PUML
@startuml
A -> B
@enduml
```

```D2
a -> b
```

```Swagger
swagger: "2.0"
info: {title: Demo, version: "1"}
paths: {}
```
''';
      final parsed = const MarkdownParser().parse(
        filePath: '/workspace/demo.md',
        source: source,
        validateLocalReferences: false,
      );
      final codeBlocks = parsed.busyDocument.blocks
          .where((block) => block.kind == BusyBlockKind.codeBlock)
          .toList();
      final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);
      final previewCode = preview.blocks
          .where((block) => block.kind == PreviewBlockKind.code)
          .toList();

      expect(codeBlocks, hasLength(4));
      expect(codeBlocks.map((block) => block.attributes['language']), [
        'MerMAID',
        'PUML',
        'D2',
        'Swagger',
      ]);
      expect(previewCode.map((block) => block.visualization?.kind), [
        VisualizationRendererKind.mermaid,
        VisualizationRendererKind.plantUml,
        VisualizationRendererKind.d2,
        VisualizationRendererKind.openApi,
      ]);
      expect(
        previewCode.map((block) => block.visualization?.originalLanguage),
        ['MerMAID', 'PUML', 'D2', 'Swagger'],
      );
      expect(
        const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
        source,
      );
    },
  );

  testWidgets(
    'dedicated visualizer rules highlight comments, keys, and keywords',
    (tester) async {
      const source = '''
```mermaid
flowchart LR
%% Mermaid comment
```
```puml
@startuml
' PlantUML comment
@enduml
```
```d2
direction: right
# D2 comment
```
```oas
openapi: 3.1.0
# OpenAPI comment
```
''';
      late List<TextSpan> spans;
      late Color foreground;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildBusyMarkTheme(
            brightness: Brightness.dark,
            accentColor: BusyMarkLinuxPalette.blueAccent,
          ),
          home: Builder(
            builder: (context) {
              foreground = BusyMarkSurfaceColors.of(context).foreground;
              final controller = BusyMarkSourceEditingController(
                text: source,
                language: SourceSyntaxLanguage.markdown,
              );
              spans = _flatten(
                controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 14),
                  withComposing: false,
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      for (final token in [
        'flowchart',
        'Mermaid comment',
        '@startuml',
        'PlantUML comment',
        'direction',
        'D2 comment',
        'openapi',
        'OpenAPI comment',
      ]) {
        expect(_color(spans, token), isNot(foreground), reason: token);
      }
    },
  );
}

List<TextSpan> _flatten(TextSpan root) {
  final result = <TextSpan>[];
  void visit(InlineSpan span) {
    if (span is! TextSpan) {
      return;
    }
    if (span.text != null && span.text!.isNotEmpty) {
      result.add(span);
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child);
    }
  }

  visit(root);
  return result;
}

Color? _color(List<TextSpan> spans, String token) {
  for (final span in spans) {
    if ((span.text ?? '').contains(token)) {
      return span.style?.color;
    }
  }
  return null;
}
