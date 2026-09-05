import 'dart:io';
import 'package:path/path.dart' as p;
import '../markdown/markdown_model.dart';
import '../math/math_coordinator.dart';
import '../visualization/visualization_coordinator.dart';
import 'html_export_models.dart';
import 'html_export_service.dart';

/// Product-path smoke coverage, invoked by the existing guarded release check.
Future<Map<String, Object?>> runHtmlReleaseSmoke({
  required Directory sourceRoot,
  required Directory outputRoot,
  required MathCoordinator math,
  required VisualizationCoordinator visualization,
}) async {
  final exporter = HtmlExportService(math: math, visualization: visualization);
  const markdown = r'''---
lang: en
description: An offline BusyMark HTML export
---
# Offline document

This is **semantic HTML**, with $x^2 + y^2 = z^2$ inline mathematics.

## 日本語

[Jump to tables](#tables). Footnote[^one].

3. First item
   - A nested item
4. Second item

- [x] Completed task
- [ ] Remaining task

## Tables

| Name | Value |
| :--- | ---: |
| Example | 12 |

<details><summary>Printable disclosure</summary><p>Disclosure body must print.</p><dl><dt>Term</dt><dd>Definition</dd></dl></details>

![Local image](logo.svg "A local asset")

## Mathematics

$$
\int_0^1 x^2\,dx = \frac{1}{3}
$$

## Diagrams

```mermaid
flowchart LR
  A[Source] --> B[Offline HTML]
```

```plantuml
@startuml
Alice -> Bob: Offline export
@enduml
```

```d2
source -> html: export
```

## API

```openapi
openapi: 3.1.0
info:
  title: Offline API
  version: 1.0.0
paths:
  /items:
    get:
      summary: List items
      responses:
        '200':
          description: A list of items
```

[^one]: A **structured footnote** with a return link.
''';
  await File(p.join(sourceRoot.path, 'logo.svg')).writeAsString(
    '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="60"><rect width="100" height="60" rx="8" fill="#1559aa"/><text x="8" y="35" fill="white">BusyMark</text></svg>',
  );
  final documentPath = p.join(sourceRoot.path, 'offline.md');
  await File(documentPath).writeAsString(markdown);
  final document = await exporter.exportMarkdown(
    MarkdownHtmlExportRequest(
      source: markdown,
      filePath: documentPath,
      workspaceRoot: sourceRoot.path,
      destinationPath: p.join(outputRoot.path, 'offline.html'),
      mode: MarkdownMode.gfm,
      overwrite: true,
    ),
  );
  if (document.warnings.isNotEmpty) {
    throw StateError('HTML smoke diagnostics: ${document.warnings.join('; ')}');
  }
  final module = Directory(p.join(sourceRoot.path, 'writerside'));
  Future<void> put(String path, String source) async {
    final file = File(p.join(module.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
  }

  await put(
    'writerside.cfg',
    '<ihp version="2.0"><topics dir="topics"/><images dir="images"/><snippets dir="snippets"/><instance src="guide.tree"/></ihp>',
  );
  await put(
    'guide.tree',
    '<instance-profile id="guide" name="Offline Guide" start-page="Start.topic"><toc-element topic="Start.topic" toc-title="Home"><toc-element topic="Reference.topic" wip="true"/><toc-element topic="Hidden.md" hidden="true"/></toc-element></instance-profile>',
  );
  await put(
    'topics/Start.topic',
    '''<topic id="Start" title="Guide"><title instance="guide">Offline Guide</title><web-file-name>Welcome.html</web-file-name><p>Portable documentation.</p><include from="Reference.topic" element-id="shared"><var name="product" value="BusyMark"/></include><tabs><tab title="Linux"><p>All Linux instructions.</p></tab><tab title="Windows"><p>All Windows instructions.</p></tab></tabs><procedure title="Export"><step><p>Select HTML.</p></step><step><p>Open the output.</p></step></procedure><a href="Reference.topic" anchor="table"/><a href="Hidden.md"/></topic>''',
  );
  await put(
    'topics/Reference.topic',
    '''<topic id="Reference" title="Reference"><snippet id="shared"><var name="product" value="Default"/><p>Welcome to %product%.</p></snippet><chapter id="table" title="Table"><table><tr><td colspan="2">Both columns</td></tr><tr><td>One</td><td>Two</td></tr></table></chapter><chapter title="Expandable" collapsible="true"><p>All details are printable.</p></chapter><code-block lang="mermaid" src="flow.mmd"/></topic>''',
  );
  await put('topics/Hidden.md', '# Hidden topic\n\nLink-accessible content.');
  await put(
    'snippets/flow.mmd',
    'flowchart LR\n  A[Topic] --> B[Shared assets]',
  );
  final site = await exporter.exportWriterside(
    projectRoot: module.path,
    moduleRoot: module.path,
    instanceId: 'guide',
    destinationPath: p.join(outputRoot.path, 'writerside'),
    overwrite: true,
  );
  if (site.warnings.isNotEmpty) {
    throw StateError(
      'Writerside HTML smoke diagnostics: ${site.warnings.join('; ')}',
    );
  }
  return {
    'markdownHtml': document.entryPointPath,
    'writersideHtml': site.entryPointPath,
    'htmlPages': site.pageCount + 1,
    'htmlWarnings': 0,
  };
}
