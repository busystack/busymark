import 'dart:io';

import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/math_syntax.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/visualization/visualization_models.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_diagram_source_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();
  const serializer = BusyMarkMarkdownSerializer();

  test('Writerside math forms use semantic math nodes and round-trip', () {
    const source = r'''# Math

Inline <math>x &lt; y</math> and $z$.

<code-block lang="tex">
<![CDATA[\sum_{i=1}^n i < n^2]]>
</code-block>

```tex
\mathbf{R}
```

$$
\int_0^1 x\,dx
$$
''';
    final parsed = parser.parse(
      filePath: '/workspace/topics/math.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final blocks = parsed.busyDocument.blocks;
    final displayMath = blocks
        .where((block) => block.kind == BusyBlockKind.math)
        .toList();
    final inlineMath = blocks
        .expand(_allInlines)
        .where((inline) => inline.kind == BusyInlineKind.math)
        .where(
          (inline) => inline.attributes[busyMarkMathDisplayAttribute] != 'true',
        )
        .toList();

    expect(displayMath, hasLength(3));
    expect(
      displayMath.map(
        (block) => block.attributes[busyMarkMathSourceFormAttribute],
      ),
      [
        BusyMathSourceForm.writersideTexElement.name,
        BusyMathSourceForm.writersideTexFence.name,
        BusyMathSourceForm.doubleDollarDisplay.name,
      ],
    );
    expect(displayMath.first.plainText, r'\sum_{i=1}^n i < n^2');
    expect(inlineMath.map((inline) => inline.text), ['x < y', 'z']);
    expect(serializer.serialize(parsed.busyDocument), source);

    final semantic = displayMath.first;
    const editedExpression = r'\sum_{i=1}^n i > 0';
    final edited = semantic.copyWith(
      inlines: [
        BusyInline(
          kind: BusyInlineKind.math,
          text: editedExpression,
          attributes: {
            ...semantic.inlines.single.attributes,
            busyMarkMathExpressionAttribute: editedExpression,
          },
        ),
      ],
      attributes: {
        ...semantic.attributes,
        busyMarkMathExpressionAttribute: editedExpression,
      },
      dirty: true,
    );
    final editedSource = serializer.serialize(
      parsed.busyDocument.copyWith(
        blocks: [
          for (final block in blocks) block.id == semantic.id ? edited : block,
        ],
      ),
    );
    expect(
      editedSource,
      contains(
        '<code-block lang="tex">\n'
        r'\sum_{i=1}^n i &gt; 0'
        '\n</code-block>',
      ),
    );
    final reparsed = parser.parse(
      filePath: '/workspace/topics/math.md',
      source: editedSource,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    expect(
      reparsed.busyDocument.blocks
          .where((block) => block.kind == BusyBlockKind.math)
          .first
          .plainText,
      editedExpression,
    );
  });

  test('ordinary Markdown does not reinterpret Writerside TeX forms', () {
    const source = '''<code-block lang="tex">x</code-block>

```tex
x
```
''';
    final parsed = parser.parse(
      filePath: '/workspace/document.md',
      source: source,
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );

    expect(
      parsed.busyDocument.blocks.where(
        (block) => block.kind == BusyBlockKind.math,
      ),
      isEmpty,
    );
    expect(
      parsed.busyDocument.blocks.where(
        (block) => block.kind == BusyBlockKind.codeBlock,
      ),
      hasLength(1),
    );
    expect(parsed.busyDocument.blocks.first.kind, BusyBlockKind.htmlBlock);
    expect(serializer.serialize(parsed.busyDocument), source);
  });

  test('Writerside semantic and fenced diagrams share visualizers', () {
    const source = '''<code-block lang="Mermaid">
flowchart LR
  A --> B
</code-block>

<code-block lang="plantuml"><![CDATA[
@startuml
A -> B
@enduml
]]></code-block>

<code-block lang="D2" src="graphs/architecture.d2"/>

```mermaid
flowchart TD
  C --> D
```

```plantuml
@startuml
C -> D
@enduml
```

```D2
```
{ src="graphs/architecture.d2" }
''';
    final parsed = parser.parse(
      filePath: '/workspace/topics/diagrams.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final codeBlocks = parsed.busyDocument.blocks
        .where((block) => block.kind == BusyBlockKind.codeBlock)
        .toList();
    final preview = const BusyMarkPreviewBuilder().build(parsed.busyDocument);
    final diagrams = preview.blocks
        .where((block) => block.visualization != null)
        .toList();

    expect(codeBlocks, hasLength(6));
    expect(diagrams, hasLength(6));
    expect(diagrams.map((block) => block.visualization!.kind), [
      VisualizationRendererKind.mermaid,
      VisualizationRendererKind.plantUml,
      VisualizationRendererKind.d2,
      VisualizationRendererKind.mermaid,
      VisualizationRendererKind.plantUml,
      VisualizationRendererKind.d2,
    ]);
    expect(codeBlocks[2].attributes['src'], 'graphs/architecture.d2');
    expect(codeBlocks.last.attributes['src'], 'graphs/architecture.d2');
    expect(
      codeBlocks.last.rawSource,
      contains('{ src="graphs/architecture.d2" }'),
    );
    expect(serializer.serialize(parsed.busyDocument), source);

    final ordinary = parser.parse(
      filePath: '/workspace/diagrams.md',
      source: '''```D2
```
{ src="graphs/architecture.d2" }
''',
      mode: MarkdownMode.commonMark,
      validateLocalReferences: false,
    );
    final ordinaryCode = ordinary.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.codeBlock,
    );
    expect(ordinaryCode.attributes['src'], isNull);
    expect(
      ordinary.busyDocument.blocks.where(
        (block) => block.kind == BusyBlockKind.paragraph,
      ),
      hasLength(1),
    );
  });

  test(
    'referenced diagram source is constrained to the Writerside root',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-writerside-diagram-',
      );
      final outside = await Directory.systemTemp.createTemp(
        'busymark-writerside-outside-',
      );
      addTearDown(() async {
        await root.delete(recursive: true);
        await outside.delete(recursive: true);
      });
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      final graphs = Directory(p.join(root.path, 'graphs'))..createSync();
      final topicPath = p.join(topics.path, 'diagram.md');
      File(topicPath).writeAsStringSync('# Diagram\n');
      File(p.join(graphs.path, 'graph.d2')).writeAsStringSync('a -> b\n');
      final outsideFile = File(p.join(outside.path, 'outside.d2'))
        ..writeAsStringSync('secret\n');
      const loader = WritersideDiagramSourceLoader();

      expect(
        await loader.load(
          reference: '../graphs/graph.d2',
          documentPath: topicPath,
          workspaceRoot: root.path,
        ),
        'a -> b\n',
      );
      await expectLater(
        loader.load(
          reference: p.join('..', '..', p.basename(outside.path), 'outside.d2'),
          documentPath: topicPath,
          workspaceRoot: root.path,
        ),
        throwsA(
          isA<WritersideDiagramSourceException>().having(
            (error) => error.failure,
            'failure',
            WritersideDiagramSourceFailure.outsideWorkspace,
          ),
        ),
      );
      await Link(p.join(graphs.path, 'linked.d2')).create(outsideFile.path);
      await expectLater(
        loader.load(
          reference: '../graphs/linked.d2',
          documentPath: topicPath,
          workspaceRoot: root.path,
        ),
        throwsA(
          isA<WritersideDiagramSourceException>().having(
            (error) => error.failure,
            'failure',
            WritersideDiagramSourceFailure.outsideWorkspace,
          ),
        ),
      );
      File(p.join(graphs.path, 'invalid.d2')).writeAsBytesSync([0xff]);
      await expectLater(
        loader.load(
          reference: '../graphs/invalid.d2',
          documentPath: topicPath,
          workspaceRoot: root.path,
        ),
        throwsA(
          isA<WritersideDiagramSourceException>().having(
            (error) => error.failure,
            'failure',
            WritersideDiagramSourceFailure.invalidUtf8,
          ),
        ),
      );
      await expectLater(
        const WritersideDiagramSourceLoader(maximumBytes: 4).load(
          reference: '../graphs/graph.d2',
          documentPath: topicPath,
          workspaceRoot: root.path,
        ),
        throwsA(
          isA<WritersideDiagramSourceException>().having(
            (error) => error.failure,
            'failure',
            WritersideDiagramSourceFailure.tooLarge,
          ),
        ),
      );
    },
  );

  test(
    'Writerside topic XML exposes TeX and diagrams to shared preview',
    () async {
      const service = WorkspaceService();
      final workspace = await service.openPath(
        'test/fixtures/writerside/basic_project',
      );
      final topicPath = p.normalize(
        p.absolute('test/fixtures/writerside/basic_project/topics/math.topic'),
      );
      const source = r'''<topic title="Math" id="math">
  <code-block lang="tex"><![CDATA[\mathbb{R}]]></code-block>
  <code-block lang="mermaid">flowchart LR
A --&gt; B</code-block>
</topic>
''';
      final preview = service.buildPreview(
        workspace.copyWith(activeFilePath: topicPath),
        source,
      )!;

      final math = preview.blocks.singleWhere(
        (block) => block.kind == PreviewBlockKind.math,
      );
      final diagram = preview.blocks.singleWhere(
        (block) => block.visualization != null,
      );
      expect(math.text, r'\mathbb{R}');
      expect(
        math.attributes[busyMarkMathSourceFormAttribute],
        BusyMathSourceForm.writersideTexElement.name,
      );
      expect(diagram.visualization!.kind, VisualizationRendererKind.mermaid);
      expect(diagram.text, 'flowchart LR\nA --> B');
    },
  );
}

Iterable<BusyInline> _allInlines(BusyBlock block) sync* {
  for (final inline in block.inlines) {
    yield inline;
    yield* _nestedInlines(inline);
  }
  for (final child in block.children) {
    yield* _allInlines(child);
  }
}

Iterable<BusyInline> _nestedInlines(BusyInline inline) sync* {
  for (final child in inline.children) {
    yield child;
    yield* _nestedInlines(child);
  }
}
