import 'dart:io';

import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/raw_html_policy.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  const service = WorkspaceService();
  Future<Workspace> reparse(Workspace workspace, String source) =>
      service.reparseDocument(
        workspace,
        DocumentBuffer(
          id: 'validation:${workspace.activeFilePath ?? 'untitled'}',
          filePath: workspace.activeFilePath,
          text: source,
          lastSavedText: source,
          dirty: true,
        ),
      );
  String path(String relative) => p.join(root.path, relative);
  Future<void> write(String relative, String source) async {
    final file = File(path(relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
  }

  const config =
      '<ihp><module name="main"/><topics dir="topics"/>'
      '<images dir="images"/><instance src="guide.tree"/></ihp>';
  Future<void> module() async {
    await write('writerside.cfg', config);
    await Directory(path('images')).create();
    await write(
      'guide.tree',
      '<instance-profile id="guide" name="Guide" '
          'start-page="a.topic"><toc-element topic="a.topic"/>'
          '<toc-element topic="b.topic"/></instance-profile>',
    );
    await write(
      'topics/b.topic',
      '<topic id="b" title="B">'
          '<p id="my-section">Target</p></topic>',
    );
  }

  List<String> signature(Iterable<Diagnostic> diagnostics) => [
    for (final diagnostic in diagnostics)
      '${diagnostic.filePath}:${diagnostic.code}:${diagnostic.sourceSpan?.startOffset}:${diagnostic.args}',
  ]..sort();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-validation-');
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'module load, topic validation, and config validation agree and clear fixes',
    () async {
      await module();
      const source =
          '<topic id="a" title="A"><img src="absent.png"/>'
          '<video src="absent.mp4"/><seealso><category ref="missing"/></seealso>'
          '<p>%unknown%</p><a href="b.topic#missing"/></topic>';
      await write('topics/a.topic', source);
      final loadedModule = await const WritersideModuleService().load(
        root.path,
      );
      var workspace = await service.openPath(root.path);
      expect(
        signature(
          workspace.diagnostics.where(
            (d) => !d.code.startsWith('writerside.schema.'),
          ),
        ),
        signature(loadedModule.diagnostics),
      );
      final original = signature(workspace.diagnostics);
      expect(
        workspace.diagnostics.map((d) => d.code),
        containsAll([
          'markdown.image.missing-file',
          'markdown.image.missing-alt',
          'writerside.video.missing-file',
          'writerside.category.unresolved',
          'writerside.variable.unresolved',
          'writerside.link.unavailable',
        ]),
      );
      workspace = await reparse(workspace, source);
      expect(signature(workspace.diagnostics), original);
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('writerside.cfg')),
        config,
      );
      expect(signature(workspace.diagnostics), original);
      const fixed = '<topic id="a" title="A"><p>Fixed</p></topic>';
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('topics/a.topic')),
        fixed,
      );
      expect(
        workspace.diagnostics.where(
          (d) => d.filePath == path('topics/a.topic'),
        ),
        isEmpty,
      );
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('writerside.cfg')),
        config,
      );
      expect(
        workspace.diagnostics.where(
          (d) => d.filePath == path('topics/a.topic'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'editing a target refreshes diagnostics in the referencing topic',
    () async {
      await module();
      await write(
        'topics/a.topic',
        '<topic id="a" title="A"><a href="b.topic#my%2Dsection"/></topic>',
      );
      var workspace = await service.openPath(root.path);
      expect(signature(workspace.diagnostics), isEmpty);
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('topics/b.topic')),
        '<topic id="b" title="B"><p id="changed">Target</p></topic>',
      );
      expect(
        workspace.diagnostics
            .where((d) => d.code == 'writerside.link.unavailable')
            .map((d) => d.filePath),
        [path('topics/a.topic')],
      );
      workspace = await reparse(
        workspace,
        await File(path('topics/b.topic')).readAsString(),
      );
      expect(signature(workspace.diagnostics), isEmpty);
    },
  );

  test(
    'local variables, comments, interpolation controls and optional includes agree',
    () async {
      await module();
      const source =
          '<topic id="a" title="A"><var name="local" value="Value"/>'
          '<p>%local% %thisTopic%</p><!-- %comment% -->'
          '<code-block ignore-vars="true">%PATH%</code-block>'
          '<snippet id="local-snippet"><p>Local content</p></snippet>'
          '<include element-id="local-snippet"/>'
          '<include from="absent.topic" nullable="true"/>'
          '<include from="b.topic" element-id="absent" nullable="true"/>'
          '<a href="absent.topic" nullable="true"/></topic>';
      await write('topics/a.topic', source);
      var workspace = await service.openPath(root.path);
      expect(signature(workspace.diagnostics), isEmpty);
      workspace = await reparse(workspace, source);
      expect(signature(workspace.diagnostics), isEmpty);
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('writerside.cfg')),
        config,
      );
      expect(signature(workspace.diagnostics), isEmpty);
      final optional = workspace.writersideProject!.index.references.where(
        (reference) => reference.nullable,
      );
      expect(optional, hasLength(2));
    },
  );

  test(
    'interpolated includes agree across load, topic and config validation',
    () async {
      await module();
      await write(
        'topics/b.topic',
        '<topic id="b" title="B">'
            '<snippet id="my-section"><p>Target</p></snippet></topic>',
      );
      const source =
          '<topic id="a" title="A">'
          '<var name="target" value="b.topic"/>'
          '<var name="part" value="my-section"/>'
          '<var name="module" value="main"/>'
          '<include origin="%module%" from="%target%" element-id="%part%"/>'
          '</topic>';
      await write('topics/a.topic', source);
      var workspace = await service.openPath(root.path);
      for (final stage in ['load', 'topic', 'config']) {
        if (stage != 'load') {
          workspace = await reparse(
            workspace.copyWith(
              activeFilePath: path(
                stage == 'topic' ? 'topics/a.topic' : 'writerside.cfg',
              ),
            ),
            stage == 'topic' ? source : config,
          );
        }
        expect(signature(workspace.diagnostics), isEmpty, reason: stage);
        final module = workspace.writersideModule!;
        final topic = module.topicByReference('a.topic')!;
        final resolved = const WritersideDocumentResolver().resolve(
          topic.document,
          WritersideResolveContext(
            module: module,
            topic: topic,
            modulesByOrigin: workspace.writersideProject!.modulesByOrigin,
          ),
        );
        expect(
          resolved.document.nodes.map((node) => node.plainText).join(),
          contains('Target'),
          reason: stage,
        );
        final reference = workspace.writersideProject!.index.references
            .singleWhere((r) => r.kind == WritersideSymbolKind.snippet);
        expect(reference.value, '%target%#%part%');
        expect(reference.origin, '%module%');
      }
    },
  );

  test('local variable scope identity includes its declaring topic', () async {
    await module();
    String topic(String id, String declarations) =>
        '<topic id="$id" title="$id">$declarations<p>%product%</p></topic>';
    const declaration = '<var name="product" value="A"/>';
    await write('topics/a.topic', topic('a', declaration));
    await write(
      'topics/b.topic',
      topic('b', '<var name="product" value="B"/>'),
    );
    var workspace = await service.openPath(root.path);
    expect(signature(workspace.diagnostics), isEmpty);
    workspace = await reparse(workspace, topic('a', declaration + declaration));
    final duplicates = workspace.diagnostics.where(
      (d) => d.code == 'writerside.index.duplicate-symbol',
    );
    expect(duplicates, hasLength(1));
    expect(duplicates.single.filePath, path('topics/a.topic'));
    expect(
      duplicates.single.relatedSpans.single.filePath,
      path('topics/a.topic'),
    );
    workspace = await reparse(
      workspace,
      topic(
        'a',
        '$declaration'
            '<chapter title="Nested"><var name="product" value="Nested"/><p>%product%</p></chapter>',
      ),
    );
    expect(signature(workspace.diagnostics), isEmpty);
  });

  test('cross-module includes refresh when their target changes', () async {
    for (final name in ['main', 'shared']) {
      await write(
        '$name/writerside.cfg',
        '<ihp><module name="$name"/><topics dir="topics"/></ihp>',
      );
    }
    await write(
      'main/topics/a.topic',
      '<topic id="a" title="A">'
          '<include origin="shared" from="b.topic" element-id="part"/></topic>',
    );
    await write(
      'shared/topics/b.topic',
      '<topic id="b" title="B">'
          '<snippet id="part"><p>Shared</p></snippet></topic>',
    );
    var workspace = await service.openPath(root.path);
    expect(
      workspace.diagnostics.where(
        (d) => d.code.contains('include') || d.code.contains('reference'),
      ),
      isEmpty,
    );
    workspace = await reparse(
      workspace.copyWith(activeFilePath: path('shared/topics/b.topic')),
      '<topic id="b" title="B"><snippet id="part"><p>Shared</p></snippet></topic>',
    );
    expect(workspace.writersideModule!.config.moduleName, 'shared');
    workspace = await service.withDocumentSources(workspace, {
      path('shared/topics/b.topic'): '<topic id="b" title="B"/>',
    });
    expect(
      workspace.diagnostics.map((d) => d.code),
      contains('writerside.include.unresolved-element'),
    );
    workspace = await service.withDocumentSources(workspace, {
      path('shared/topics/b.topic'): await File(
        path('shared/topics/b.topic'),
      ).readAsString(),
    });
    expect(
      workspace.diagnostics.where(
        (d) => d.code.contains('include') || d.code.contains('reference'),
      ),
      isEmpty,
    );
  });

  test(
    'malformed glossary and keymap XML report the supporting file and clear after repair',
    () async {
      await module();
      await write('topics/a.topic', '<topic id="a" title="A"/>');
      await write(
        'cfg/buildprofiles.xml',
        '<buildprofiles><shortcuts><src>keymap.xml</src></shortcuts></buildprofiles>',
      );
      await write('cfg/glossary.xml', '<glossary>\n<term');
      await write('keymap.xml', '<keymap>\n<action');
      var workspace = await service.openPath(root.path);
      final failures = workspace.diagnostics.where(
        (d) => d.code == 'writerside.reference-data.invalid-xml',
      );
      expect(
        failures.map((d) => d.filePath),
        unorderedEquals([path('cfg/glossary.xml'), path('keymap.xml')]),
      );
      expect(failures.every((d) => d.sourceSpan != null), isTrue);
      for (final entry in {
        'cfg/glossary.xml': '<glossary/>',
        'keymap.xml': '<keymap/>',
      }.entries) {
        workspace = await reparse(
          workspace.copyWith(activeFilePath: path(entry.key)),
          entry.value,
        );
      }
      expect(
        workspace.diagnostics.where(
          (d) => d.code == 'writerside.reference-data.invalid-xml',
        ),
        isEmpty,
      );
    },
  );

  test(
    'Markdown validation preserves other files and scan warnings while clearing active errors',
    () async {
      await write('a.md', '# A\n');
      await write('b.md', '# B\n[Broken](missing.md)\n');
      var workspace = await service.openPath(root.path);
      final scanWarning = Diagnostic(
        code: 'workspace.scan.truncated',
        severity: DiagnosticSeverity.warning,
        filePath: path('a.md'),
      );
      workspace = workspace.copyWith(
        activeFilePath: path('a.md'),
        diagnostics: [...workspace.diagnostics, scanWarning],
      );
      final before = signature(workspace.diagnostics);
      workspace = await reparse(workspace, '# A\n');
      expect(signature(workspace.diagnostics), before);
      workspace = await reparse(
        workspace.copyWith(activeFilePath: path('b.md')),
        '# Fixed\n',
      );
      expect(workspace.diagnostics, [scanWarning]);
    },
  );

  test(
    'linked anchors use dirty buffers and canonical self-links, caching targets',
    () async {
      await write('a.md', '# Old\n');
      await write('b.md', '# Saved\n');
      await Link(path('alias.md')).create(path('a.md'));
      final parser = _CountingParser();
      final parsed = await parser.parseAsync(
        filePath: path('a.md'),
        source:
            '# New heading\n'
            '[self](a.md#new-heading) [alias](alias.md#new-heading)\n'
            '${List.filled(20, '[target](b.md#dirty)').join('\n')}\n',
        workspaceRoot: root.path,
        sourceOverrides: {path('b.md'): '# Dirty\n'},
      );
      expect(parsed.diagnostics, isEmpty);
      expect(parser.parses[path('a.md')], 1);
      expect(parser.parses[path('b.md')], 1);
      expect(parser.parses[path('alias.md')], isNull);
      final disk = await const MarkdownParser().parseAsync(
        filePath: path('a.md'),
        source: '# A\n[target](b.md#saved)',
        workspaceRoot: root.path,
      );
      expect(disk.diagnostics, isEmpty);
    },
  );

  test(
    'large buffered targets parse asynchronously and missing saved targets use their buffers',
    () async {
      await write('a.md', '# A\n');
      final large =
          '# Buffered\n\n${List.filled(4000, 'A paragraph of document text.\n\n').join()}';
      final parsed = await const MarkdownParser().parseAsync(
        filePath: path('a.md'),
        source: '# A\n[one](b.md#buffered) [two](b.md#buffered)\n',
        workspaceRoot: root.path,
        sourceOverrides: {path('b.md'): large},
      );
      expect(parsed.diagnostics, isEmpty);
      expect(File(path('b.md')).existsSync(), isFalse);
    },
  );

  test('front matter requires complete delimiter lines with LF and CRLF', () {
    const parser = MarkdownParser();
    for (final source in ['---example\n# Title\n', '---something\n']) {
      final parsed = parser.parse(filePath: 'a.md', source: source);
      expect(
        parsed.diagnostics.where(
          (d) => d.code == 'markdown.front-matter.malformed',
        ),
        isEmpty,
      );
      expect(parsed.busyDocument.rawFrontMatter, isNull);
    }
    for (final newline in ['\n', '\r\n']) {
      final source = [
        '---',
        'title: Metadata',
        '---something',
        '---',
        '# Body',
      ].join(newline);
      final parsed = parser.parse(filePath: 'a.md', source: source);
      expect(parsed.title, 'Metadata');
      expect(parsed.busyDocument.rawFrontMatter, contains('---something'));
      expect(parsed.headings.map((h) => h.text), ['Body']);
    }
    final malformed = parser.parse(
      filePath: 'a.md',
      source: '---\ntitle: Metadata\n---something',
    );
    expect(
      malformed.diagnostics.map((d) => d.code),
      contains('markdown.front-matter.malformed'),
    );
  });

  test(
    'HTML diagnostics exclude prose and literal code without relaxing rendering policy',
    () {
      const parser = MarkdownParser();
      const source =
          'JavaScript: a language. `onclick="example"`\n\n'
          '`<script>alert(1)</script>`\n\n'
          '    <script>alert(1)</script>\n\n'
          '```html\n<script>alert(1)</script>\n```\n\n'
          'Escaped: &lt;script&gt; and \\<script>.\n';
      final parsed = parser.parse(filePath: 'a.md', source: source);
      expect(
        parsed.diagnostics.where((d) => d.code == 'markdown.raw-html.unsafe'),
        isEmpty,
      );
      final unsafe = parser.parse(
        filePath: 'a.md',
        source: '$source\n<a\nhref="javascript:alert(1)">bad</a>',
      );
      expect(
        unsafe.diagnostics.map((d) => d.code),
        contains('markdown.raw-html.unsafe'),
      );
      expect(hasUnsafeHtml('<script>alert(1)</script>'), isTrue);
      expect(hasUnsafeHtml('<a href="javascript:alert(1)">bad</a>'), isTrue);
    },
  );

  test(
    'location maps are reused within a parse and released between parses',
    () {
      const source = 'a\nb\nc\n';
      SourceLocationMapper? first;
      SourceLocationMapper.withSource(source, () {
        first = SourceLocationMapper.forSource(source);
        expect(
          identical(first, SourceLocationMapper.forSource(source)),
          isTrue,
        );
        final span = SourceSpan.fromOffsets(
          filePath: 'a.md',
          source: source,
          startOffset: 2,
          endOffset: 5,
        );
        expect(span.startLine, 2);
        expect(span.endLine, 3);
      });
      SourceLocationMapper.withSource(source, () {
        expect(
          identical(first, SourceLocationMapper.forSource(source)),
          isFalse,
        );
      });
    },
  );
}

class _CountingParser extends MarkdownParser {
  final parses = <String, int>{};
  @override
  ParsedMarkdownDocument parse({
    required String filePath,
    required String source,
    MarkdownMode mode = MarkdownMode.commonMark,
    String? workspaceRoot,
    bool validateLocalReferences = true,
  }) {
    parses.update(filePath, (count) => count + 1, ifAbsent: () => 1);
    return super.parse(
      filePath: filePath,
      source: source,
      mode: mode,
      workspaceRoot: workspaceRoot,
      validateLocalReferences: validateLocalReferences,
    );
  }
}
